<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>    

<!-- Copy all other elements -->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<!-- this template matches the paragraph element -->
<xsl:template match="paragraph">


    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        
        <!-- copy the content of step 1 between the content tags -->
        <content>
            <xsl:copy-of select="current()/*"/>
        </content>
        
        <!-- place branches tags and calculate branches cost and ratio -->
        <branches>
           
           <!-- Call the template to start calculating the branches -->
            <xsl:call-template name="create_branches">
                <!-- Calculation starts at the beginning of the paragraph -->
                <xsl:with-param name="start_index" select="1"/>
                <xsl:with-param name="stop_index" select="1"/>
                
                <!-- Since there are no previous breaks, this is set to 0 -->
                <xsl:with-param name="previous_break" select="0"/>
                
                <!-- new_break will store the first possible breakpoint enstop_indexed when calculating
                    branches. The next iteration will start at this start_index. It is set at -1 until the
                    next breakpoint is found. -->
                <xsl:with-param name="new_break" select="-1"/>
                
                <!-- The l_prev, y_prev and z_prev values are initialized at 0... -->
                <xsl:with-param name="l_prev" select="0"/>
                <xsl:with-param name="y_prev" select="0"/>
                <xsl:with-param name="z_prev" select="0"/>
                
                <!-- xsl:choose in order to support paragraphs with different l_maxs... -->
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
                
            </xsl:call-template>
        </branches>         
        
    </xsl:copy>
</xsl:template>
    
<!-- This template will recursively iterate over the paragraphs and write out the possible branches -->
<xsl:template name="create_branches">
    <xsl:param name="l_max"/>
    <xsl:param name="start_index"/>
    <xsl:param name="stop_index"/>
    <xsl:param name="previous_break"/>
    <xsl:param name="new_break"/>
    <xsl:param name="l_prev"/>
    <xsl:param name="y_prev"/>
    <xsl:param name="z_prev"/>
    
    <xsl:variable name="stop_element"  select="./*[position() = $stop_index]"/>
    <xsl:variable name="stop_element_type" select="name($stop_element)"/>

    <xsl:choose>
        
        <!-- We should start at the first box after the previous breakpoint (or on the first line),
                therefore, we loop through the text and look for the next box... -->
        <xsl:when test="$start_index != 1 and name(./*[position() = $start_index]) != 'box'">
            <xsl:call-template name="create_branches">
                <xsl:with-param name="l_max" select="$l_max"/>
                <xsl:with-param name="start_index" select="$start_index + 1"/>
                <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                <xsl:with-param name="previous_break" select="$previous_break"/>
                <xsl:with-param name="new_break" select="$new_break"/>
                <xsl:with-param name="l_prev" select="0"/>
                <xsl:with-param name="y_prev" select="0"/>
                <xsl:with-param name="z_prev" select="0"/>
            </xsl:call-template>
        </xsl:when>
        
        <!-- If the start_index is at a box element, we can start (or continue) calculating branches starting from this element. -->
        <xsl:otherwise>

            <!-- Calculate the new l_prev value -->
            <xsl:variable name="l_curr">
                <xsl:choose>
                    
                    <!-- If the current element (at start_index $stop_index) is a glue, add the width of this element -->
                    <xsl:when test="$stop_element_type = 'glue'
                        or $stop_element_type = 'box'">
                        <xsl:value-of select="$l_prev + $stop_element/@width"/>
                    </xsl:when>
                    
                    <!-- If the current element (at start_index $stop_index) is neither a glue or a box, the value will stay the same -->
                    <xsl:otherwise>
                        <xsl:value-of select="$l_prev"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- Calculate the new y_prev value -->
            <xsl:variable name="y_curr">
                <xsl:choose>
                    
                    <!-- infinity is not supported -->
                    <xsl:when test="$stop_element_type = 'glue'">
                        <xsl:choose>
                            <xsl:when test="$stop_element/@stretchability = 'INF'">
                                <xsl:value-of select="'INF'"/>
                            </xsl:when>

                            <xsl:when test="$stop_element/@stretchability = '-INF'">
                                <xsl:value-of select="'-INF'"/>
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
            
            <!-- Calculate the new z_prev value -->
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
                    
                    <!-- When l_prev equals the l_max, the ratio is 0... -->
                    <xsl:when test="$l_max = $l_curr">
                        <xsl:value-of select="0"/>
                    </xsl:when>
                    
                    <!-- l_prev is smaller than the l_max... -->
                    <xsl:when test="$l_max > $l_curr">
                        <xsl:choose>
                            
                            <!-- If the stretchabilities are infinite, the ratio will be 0... -->
                            <xsl:when test="$y_curr = 'INF' or $y_curr = '-INF'">
                                <xsl:value-of select="0"/>
                            </xsl:when>
                            
                            <!-- If the stretchabilities are greater than 0 (and not infinite), calculate the ratio... -->
                            <xsl:when test="$y_curr > 0">
                                <xsl:value-of select="($l_max - ($l_curr)) div $y_curr"/>
                            </xsl:when>
                            
                            <!-- In any other case, set the ratio to 'NaN' -->
                            <xsl:otherwise>
                                <xsl:value-of select="'NaN'"/>
                            </xsl:otherwise>
                            
                        </xsl:choose>
                    </xsl:when>
                    
                    <!-- When l_prev is greater than the l_max, the ratio will be negative.
                        For simplicity reasons, this will not be calculated and a value of 'negative' is chosen instead. -->
                    <xsl:when test="$l_curr > $l_max">
                        <!--<xsl:value-of select="negative"/-->
                        <xsl:value-of select="($l_max - ($l_curr)) div $z_curr"/>
                    </xsl:when>
                    
                </xsl:choose>
            </xsl:variable>

            <!-- Define the cost -->
            <xsl:variable name="cost">
                <xsl:choose>
                    
                    <!-- When the ratio is 0 or the penalty -INF, set the cost to -INF -->
                    <xsl:when test="$ratio = 0 or $stop_element/@penalty = '-INF'">
                        <!--<xsl:value-of select="'-INF'"/>-->
                        <!-- A cost of -INF will cause that a random branch is chosen at the end of the paragraph
                            (for example, 5 - INF is the same as 1 - INF). Therefore a value of 0 is chosen instead of -INF. -->
                        <xsl:value-of select="0"/>
                    </xsl:when>
                    
                    <!-- Set the cost to INF when the ratio is (-)INF, < -1 or 'NaN'... --> 
                    <xsl:when test="$ratio = 'NaN' or $ratio = 'INF' or $ratio = '-INF' or -1 > $ratio">
                        <xsl:value-of select="'INF'"/>
                    </xsl:when>
                    
                    <!-- In all other cases, calculate the cost... -->
                    <xsl:otherwise>
                        <xsl:value-of select="floor(100 * $ratio * $ratio * $ratio + 0.5)"/>
                    </xsl:otherwise>
                    
                </xsl:choose>           
            </xsl:variable>
            
            <xsl:if test="($stop_element/@break = 'required'
                        or $stop_element/@break = 'optional')
                        and $ratio != 'NaN' and $ratio > 0
                        and $stop_index != $start_index">
                <xsl:call-template name="writeBranch">
                    <xsl:with-param name="ratio" select="$ratio"/>
                    <xsl:with-param name="cost" select="$cost"/>
                </xsl:call-template>
            </xsl:if>
            
            <!-- recursion -->
            <xsl:choose>
            
                <!-- Continue with the recursion if we're not at the end of the paragraph... -->
                <xsl:when test="0 > $ratio or $stop_element/@break = 'required'">
                    
                    <!-- If no new next breakpoint was enstop_indexed, we are at the end of the paragraph ==> Stop -->
                    <xsl:if test="$new_break != -1">
                        <xsl:call-template name="create_branches">
                            <xsl:with-param name="l_max" select="$l_max"/>
                            
                            <!-- Restart 1 element after the break before the previous start... --> 
                            <xsl:with-param name="start_index" select="$new_break + 1"/>
                            <xsl:with-param name="stop_index" select="$new_break + 1"/>
                            
                            <!-- The new 'previous' start_index in the branches will be the 'new_break' start_index -->
                            <xsl:with-param name="previous_break" select="$new_break"/>
                            <xsl:with-param name="new_break" select="-1"/>
                            
                            <!-- The element at 'new_break' might be the first element of a new set of branches.
                                Therefore, we initialize the l_prev value with the the current box or glue width if necessary. -->
                            <xsl:with-param name="l_prev">
                                <xsl:choose>
                                    <xsl:when test="name(./*[position() = $new_break]) = 'box'
                                        or name(./*[position() = $new_break]) = 'glue'">
                                        <xsl:value-of select="./*[position() = $new_break]/@width"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="0"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:with-param>
                            
                            <!-- The element at 'new_break' might be the first element of a new set of branches.
                                Therefore, we initialize the y_prev value with the the current glue stretchability if necessary. -->
                            <xsl:with-param name="y_prev">
                                <xsl:choose>
                                    <xsl:when test="name(/*[position() = $new_break]) = 'glue'">
                                        <xsl:value-of select="./*[position() = $new_break]/@stretchability"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="0"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:with-param>
                            
                            <!-- The element at 'new_break' might be the first element of a new set of branches.
                                Therefore, we initialize the z_prev value with the the current glue shrinkability if necessary. -->
                            <xsl:with-param name="z_prev">
                                <xsl:choose>
                                    <xsl:when test="name(./*[position() = $new_break]) = 'glue'">
                                        <xsl:value-of select="./*[position() = $new_break]/@shrinkability"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="0"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:with-param>
                            
                        </xsl:call-template>
                        </xsl:if>                                
                    
                </xsl:when>
                
                <!-- If we are not yet at the end of the paragraph, continue the recursion... -->
                <xsl:otherwise>                            
                    <xsl:call-template name="create_branches">
                        <xsl:with-param name="l_max" select="$l_max"/>
                        
                        <xsl:with-param name="start_index" select="$start_index"/>
                        <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                        
                        <xsl:with-param name="previous_break" select="$previous_break"/>
                        <xsl:with-param name="new_break">
                            <xsl:choose>
                                <xsl:when test="$new_break = -1 and ($stop_element/@break = 'optional'
                                            or $stop_element/@break = 'required')"> 
                                            <!--and $stop_index &gt; $start_index">-->
                                            <xsl:value-of select="$stop_index"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$new_break"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                 
                        <!-- Pass the new l_prev, y_prev and z_prev values -->
                        <xsl:with-param name="l_prev" select="$l_curr"/>
                        <xsl:with-param name="y_prev" select="$y_curr"/>
                        <xsl:with-param name="z_prev" select="$z_curr"/>
                       
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

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
                    <!-- A cost of -INF will cause that a random branch is chosen at the end of the paragraph
                (for example, 5 - INF is the same as 1 - INF). Therefore a value of 0 is chosen instead of -INF. -->
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