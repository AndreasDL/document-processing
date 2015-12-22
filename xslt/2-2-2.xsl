<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>    

<!-- Copy all other elements (document)-->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="paragraph">
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        
        <!-- put content in place -->
        <content>
            <xsl:copy-of select="current()/*"/>
        </content>

        <!-- here is where it starts to get interesting -->
        <branches>
            <xsl:call-template name="create_branches">
                <!-- correct line width -->
                <xsl:with-param name="l_max">
                    <xsl:choose>
                        <xsl:when test="string-length(@line-width)">
                            <xsl:value-of select="@line-width"/>>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="/document/@line-width"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>

                <!-- Calculation starts at the beginning of the paragraph -->
                <xsl:with-param name="start_index" select="1"/>
                <xsl:with-param name="stop_index" select="1"/>
                <xsl:with-param name="curr_break" select="0"/>
                
                <!-- init sums at 0 -->
                <xsl:with-param name="l_prev" select="0"/>
                <xsl:with-param name="y_prev" select="0"/>
                <xsl:with-param name="z_prev" select="0"/>
            </xsl:call-template>
        </branches>         
    </xsl:copy>
</xsl:template>

<!-- This is where the magic happens -->
<xsl:template name="create_branches">
    <xsl:param name="l_max"/>
    <xsl:param name="start_index"/>
    <xsl:param name="stop_index"/>
    <xsl:param name="curr_break"/>
    
    <xsl:param name="l_prev"/>
    <xsl:param name="y_prev"/>
    <xsl:param name="z_prev"/>
    
    <xsl:variable name="stop_element"  select="./*[position() = $stop_index]"/>
    <xsl:variable name="stop_element_type" select="name($stop_element)"/>

    <xsl:choose>
        
        <!-- skip all whitespace in front of first box of a paragraph -->
        <xsl:when test="$start_index != 1 and name(./*[position() = $start_index]) != 'box'">
            <xsl:call-template name="create_branches">
                <xsl:with-param name="l_max" select="$l_max"/>
                <xsl:with-param name="start_index" select="$start_index + 1"/>
                <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                <xsl:with-param name="curr_break" select="$curr_break"/>
                <xsl:with-param name="l_prev" select="0"/>
                <xsl:with-param name="y_prev" select="0"/>
                <xsl:with-param name="z_prev" select="0"/>
            </xsl:call-template>
        </xsl:when>
        
        <xsl:otherwise>

            <!-- calculate l_curr -->
            <xsl:variable name="l_curr">
                <xsl:choose>
                    <!-- penalty ==> nothing changes -->
                    <xsl:when test="$stop_element_type = 'penalty'">
                        <xsl:value-of select="$l_prev"/>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:value-of select="$l_prev + $stop_element/@width"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- calculate y_curr -->
            <xsl:variable name="y_curr">
                <xsl:choose>
                    <xsl:when test="$stop_element_type = 'glue'">
                        <!-- infinity is not supported, when -INF or +INF set this value -->
                        <xsl:choose>
                            <xsl:when test="number($stop_element/@stretchability) = 'NaN'">
                                <xsl:value-of select="$stop_element/@stretchability"/>
                            </xsl:when>
                            
                            <xsl:otherwise>
                                <xsl:value-of select="$y_prev + $stop_element/@stretchability"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    
                    <!-- no glue, no changes -->
                    <xsl:otherwise>
                        <xsl:value-of select="$y_prev"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- calculate z_curr -->
            <xsl:variable name="z_curr">
                <xsl:choose>
                    <xsl:when test="$stop_element_type = 'glue'">
                        <xsl:value-of select="$z_prev + $stop_element/@shrinkability"/>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:value-of select="$z_prev"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- Calculate the ratio -->
            <xsl:variable name="ratio">
                <xsl:choose>
                    <!-- perfect fit -->
                    <xsl:when test="$l_max = $l_curr">
                        <xsl:value-of select="0"/>
                    </xsl:when>
                    
                    <!-- shrink -->
                    <xsl:when test="$l_curr > $l_max">
                        <xsl:value-of select="($l_max - ($l_curr)) div $z_curr"/>
                    </xsl:when>

                    <!-- stretch ($l_curr < $l_max) -->
                    <xsl:otherwise>
                        <xsl:choose>
                            <!-- stretch = inf => ratio = 0 -->
                            <xsl:when test="number($y_curr) = 'NaN'">
                                <xsl:value-of select="0"/>
                            </xsl:when>
                            
                            <!-- normal case -->
                            <xsl:when test="$y_curr > 0">
                                <xsl:value-of select="($l_max - ($l_curr)) div $y_curr"/>
                            </xsl:when>
                            
                            <!-- < 0 => undef -->
                            <xsl:otherwise>
                                <xsl:value-of select="'NaN'"/>
                            </xsl:otherwise>
                            
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- Define the cost -->
            <xsl:variable name="cost">
                <xsl:choose>
                    
                    <!-- When the ratio is 0 or the penalty -INF, the cost is -INF -->
                    <xsl:when test="$ratio = 0 or $stop_element/@penalty = '-INF'">
                        <!-- -INF cost => picks a random branch since X - INF = -INF , fix this by using 0-->
                        <xsl:value-of select="0"/>
                    </xsl:when>
                    
                    <!-- ratio < -1 or undef? => inf cost --> 
                    <xsl:when test="$ratio = 'NaN' or -1 > number($ratio)">
                        <xsl:value-of select="'INF'"/>
                    </xsl:when>
                    
                    <!-- calculate cost, ignore absolute value, (ratio < 0 is ignored anyway and will never show up in the output) -->
                    <xsl:otherwise>
                        <xsl:value-of select="floor(100 * $ratio * $ratio * $ratio + 0.5)"/>
                    </xsl:otherwise>
                    
                </xsl:choose>           
            </xsl:variable>
            
            <!-- write branch when needed -->
            <xsl:if test="$stop_element/@break != 'prohibited' and $stop_index != $start_index and $ratio != 'NaN' and $ratio > 0 ">
                <xsl:call-template name="writeBranch">
                    <xsl:with-param name="ratio" select="$ratio"/>
                    <xsl:with-param name="cost" select="$cost"/>
                </xsl:call-template>
            </xsl:if>
            
            <!-- recursion, ugly code-->
            <xsl:choose>
                <!-- not at end of paragraph -->
                <!-- not => ugly fix for NaN etc -->
                <xsl:when test="$stop_element/@break != 'required' and not(0 > $ratio)">
                    <xsl:call-template name="create_branches">
                        <xsl:with-param name="l_max" select="$l_max"/>
                        
                        <xsl:with-param name="start_index" select="$start_index"/>
                        <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                        <xsl:with-param name="curr_break">
                            <xsl:choose>
                                <xsl:when test="$curr_break = 0 and ($stop_element/@break = 'optional' or $stop_element/@break = 'required')"> 
                                    <xsl:value-of select="$stop_index"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$curr_break"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                 
                        <!-- update l,y,z values -->
                        <xsl:with-param name="l_prev" select="$l_curr"/>
                        <xsl:with-param name="y_prev" select="$y_curr"/>
                        <xsl:with-param name="z_prev" select="$z_curr"/>
                    </xsl:call-template>
                </xsl:when>                            

                <!-- required break => end of paragraph -->
                <xsl:when test="$curr_break != 0">
                    <xsl:call-template name="create_branches">
                        <xsl:with-param name="l_max" select="$l_max"/>
                        
                        <!-- continue one element after the break --> 
                        <xsl:with-param name="start_index" select="$curr_break + 1"/>
                        <xsl:with-param name="stop_index" select="$curr_break + 1"/>

                        <!-- reset break index -->
                        <xsl:with-param name="curr_break" select="0"/>
                        
                        <!-- last element might be part of new paragraph -->
                        <xsl:with-param name="l_prev">
                            <xsl:choose>
                                <xsl:when test="name(./*[position() = $curr_break]) != 'penalty'">
                                    <xsl:value-of select="./*[position() = $curr_break]/@width"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="0"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                        
                        <xsl:with-param name="y_prev">
                            <xsl:choose>
                                <xsl:when test="name(/*[position() = $curr_break]) = 'glue'">
                                    <xsl:value-of select="./*[position() = $curr_break]/@stretchability"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="0"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                        
                        <xsl:with-param name="z_prev">
                            <xsl:choose>
                                <xsl:when test="name(./*[position() = $curr_break]) = 'glue'">
                                    <xsl:value-of select="./*[position() = $curr_break]/@shrinkability"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="0"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                    </xsl:call-template>   
                </xsl:when>

                <!-- else => no recursion !! -->                      
                <xsl:otherwise/>
            </xsl:choose>
        
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- write branch to output -->
<xsl:template name="writeBranch">
    <xsl:param name="ratio"/>
    <xsl:param name="cost"/>

    <branch>
        <xsl:attribute name="ratio">
            <xsl:value-of select="$ratio"/>
        </xsl:attribute>

        <xsl:choose>
            <xsl:when test="$ratio = 0">
                <xsl:attribute name="cost">
                    <!-- -INF cost => picks a random branch since X - INF = -INF , fix this by using 0-->
                    <xsl:value-of select="0"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="cost">
                    <xsl:value-of select="format-number($cost, '#')"/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </branch>
</xsl:template>
</xsl:stylesheet>    