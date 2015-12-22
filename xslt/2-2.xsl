<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="no"/>

<!-- step 2, please run the preprocessing step in 2-1.xsl first -->
<xsl:template match="document|@*">
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates select="paragraph">
            <xsl:variable name="doc_line_width" select="@line-width"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

<xsl:template match="document/paragraph">
    <xsl:param name="doc_line_width"/>

    <!-- fix the content part -->
    <xsl:copy>
        <!-- attribute fix one-liner -->
        <xsl:apply-templates select="@*"/>

        <!--fix content == copy of original data -->
        <content>
            <xsl:copy-of select="node()"/>
        </content>

        <!-- fix the branches -->
        <branches>
            <xsl:call-template name="calcBranch">
                <!--line runs from start_index until the stop_index-->
                <xsl:with-param name="start_index" select="1"/>
                <xsl:with-param name="stop_index" select="1"/>

                <!-- keep track of breaks -->
                <xsl:with-param name="break_prev" select="0"/>
                <xsl:with-param name="break_curr" select="-1"/>

                <!--check if line-width is overridden by the paragraph element -->
                <xsl:with-param name="l_max">
                    <xsl:choose>
                        <xsl:when test="@line-width != ''">
                            <xsl:value-of select="@line-width"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$doc_line_width"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>

                <!-- init to zero -->
                <xsl:with-param name="l_prev" select="0"/>
                <xsl:with-param name="y_prev" select="0"/>
                <xsl:with-param name="z_prev" select="0"/>
            </xsl:call-template>
        </branches>
    </xsl:copy>
</xsl:template>

<!-- Fair warning: looking at this template might cause permanent eye damage -->
<xsl:template name="calcBranch">
    <xsl:param name="l_max"/>
    <xsl:param name="start_index"/>
    <xsl:param name="stop_index"/>
    <xsl:param name="break_prev"/>
    <xsl:param name="break_curr"/>

    <xsl:param name="l_prev"/>
    <xsl:param name="y_prev"/>
    <xsl:param name="z_prev"/>
    
    <!-- init some basic params, readability++ -->
    <xsl:variable name="start_element_type" select="name(./*[position() = $start_index])"/>
    <xsl:variable name="curr_element" select="./*[position() = $stop_index]"/>
    <xsl:variable name="curr_element_type" select="name($curr_element)" />
    <xsl:variable name="curr_element_break" select="$curr_element/@break"/>

    <xsl:choose>
        <!-- skip elements before the first box of the paragraph, they represent whitespace that doesn't matter -->
        <xsl:when test="$start_index != 1 and name(./*[position() = $start_index]) != 'box'">
            <xsl:call-template name="calcBranch">
                <xsl:with-param name="l_max" select="$l_max"/>

                <!-- inc indexes to jump over the element -->
                <xsl:with-param name="start_index" select="$start_index + 1"/>
                <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                <!-- reset l, y, z values -->
                <xsl:with-param name="l_prev" select="0"/>
                <xsl:with-param name="y_prev" select="0"/>
                <xsl:with-param name="z_prev" select="0"/>

                <!-- keep the breaks, since no breaks occur here -->
                <xsl:with-param name="break_prev" select="$break_prev"/>
                <xsl:with-param name="break_curr" select="$break_curr"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <!-- new l, y, z values -->
            <xsl:variable name="l_curr">
                <xsl:choose>
                    <!-- things only change when the current element type is glue or box-->
                    <xsl:when test="$curr_element_type = 'glue' or $curr_element_type = 'box'">
                        <xsl:value-of select="$l_prev + $curr_element/@width"/>
                    </xsl:when>

                    <xsl:otherwise>    
                        <xsl:value-of select="$l_prev"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:variable name="y_curr">
                <xsl:choose>
                    <!-- things only change when the current element type is glue-->
                    <xsl:when test="$curr_element_type = 'glue'">
                        <xsl:choose>
                            <!-- infinity is only 'kinda' supported -->
                            <xsl:when test="$curr_element/@stretchability = '-INF'">
                                <xsl:value-of select="-INF"/>
                            </xsl:when>

                            <xsl:when test="$curr_element/@stretchability = 'INF'">
                                <xsl:value-of select="INF"/>
                            </xsl:when>

                            <xsl:otherwise>
                                <xsl:value-of select="$y_prev + $curr_element/@stretchability"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:value-of select="$y_prev"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:variable name="z_curr">
                <xsl:choose>
                <!-- things only change when the current element type is glue -->
                    <xsl:when test="$curr_element_type = 'glue'">
                        <xsl:value-of select="$z_prev + $curr_element/@shrinkability"/>
                    </xsl:when>

                    <!-- nothing changes -->
                    <xsl:otherwise>   
                        <xsl:value-of select="$z_prev"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- fix ratio -->
            <xsl:variable name="ratio">
                <xsl:choose>

                    <!-- l_curr == l-max , perfect fit!-->
                    <xsl:when test="$l_max = $l_curr">
                        <xsl:value-of select="0"/>
                    </xsl:when>

                    <!-- l_curr < l_max stretch!-->
                    <xsl:when test="$l_max > $l_curr">
                        <!-- again infinity is not supported -->
                        <xsl:choose>
                            <xsl:when test="$y_curr = 'INF' or $y_curr = '-INF'">
                                <xsl:value-of select="0"/>
                            </xsl:when>

                            <xsl:when test="$y_curr > 0">
                                <xsl:value-of select="($l_max - $l_curr) div $y_curr"/>
                            </xsl:when>
                            
                            <!-- yj <= 0 -> ratio undefined-->
                            <xsl:otherwise>
                                <xsl:value-of select="NaN"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>

                    <!-- l-curr > l_max shrink!-->
                    <xsl:when test="$l_curr > $l_max">
                        <xsl:choose>
                            <xsl:when test="0 > $z_curr">
                                <xsl:value-of select="($l_max - $l_curr) div $z_curr"/>
                            </xsl:when>
                            
                            <!-- zj <= 0 -> ratio undefined-->
                            <xsl:otherwise>
                                <xsl:value-of select="NaN"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>

            <!-- stolen with pride from http://stackoverflow.com/questions/804421/how-can-i-calculate-the-absolute-value-of-a-number-in-xslt -->
            <xsl:variable name="abs_ratio" select=" $ratio*($ratio >=0) - $ratio*($ratio &lt; 0)"/>

            <!-- fix the cost -->
            <xsl:variable name="cost">
                <xsl:choose>
                    <!-- cost is zero when ratio is 0 of the penalty is -INF (best place to split) -->
                    <xsl:when test="$ratio = 0 or $curr_element/@penalty = '-INF'">
                        <xsl:value-of select="0"/>
                    </xsl:when>

                    <!-- cost is infinity, when ratio is INF, -INF, undef (NaN) or < -1 -->
                    <xsl:when test="$ratio = 'INF' or $ratio = '-INF' or $ratio = 'NaN' or -1 > $ratio">
                        <xsl:value-of select="'INF'"/>
                    </xsl:when> 

                    <!-- else: formula -->
                    <xsl:otherwise>
                        <xsl:value-of select="round(100 * $abs_ratio*$abs_ratio*$abs_ratio)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- spam to output -->
            <xsl:if test="$ratio != 'NaN' and 0 > $ratio and ( $curr_element_break = 'required' or $curr_element_break = 'optional' ) and $start_index != $stop_index ">
                
                <branch>
                    <xsl:attribute name="ratio">
                        <xsl:value-of select="$ratio"/>
                    </xsl:attribute>

                    <xsl:choose>
                        <xsl:when test="$ratio = 0">                            
                            <xsl:attribute name="cost">
                                <xsl:value-of select="0"/>
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="cost">
                                <xsl:value-of select="format-number($cost,'#')"/>
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>

                    <xsl:attribute name="start">
                        <xsl:value-of select="$start_index"/>
                    </xsl:attribute>

                    <xsl:attribute name="end">
                        <xsl:value-of select="$stop_index"/>
                    </xsl:attribute>

                    <xsl:attribute name="previous">
                        <xsl:value-of select="$break_prev"/>
                    </xsl:attribute>
                </branch>
            </xsl:if>
            
            <xsl:variable name="break_element" select="./*[position() = $break_curr]"/>
            <xsl:variable name="break_element_type" select="name($break_element)"/>

            <!-- recursion -->
            <xsl:choose>
                <!-- end of a paragraph -->                
                <xsl:when test="$curr_element_break = 'required' or 0 > $ratio and $break_curr != -1">
                    <xsl:call-template name="calcBranch">
                        <!-- somethings will never change -->
                        <xsl:with-param name="l_max" select="$l_max"/>
                        
                        <!-- set indexes to first element behind previous paragraph --> 
                        <xsl:with-param name="start_index" select="$break_curr + 1"/>
                        <xsl:with-param name="stop_index" select="$break_curr + 1"/>
                        
                        <!-- if the last element is not part of the current paragraph, it becomes the first element of the new paragraph -->
                        <xsl:with-param name="l_prev">
                            <xsl:choose>
                                <xsl:when test="$break_element_type = 'box'
                                    or $break_element_type = 'glue'">
                                    <xsl:value-of select="$break_element/@width"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="0"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                        
                        <xsl:with-param name="y_prev">
                            <xsl:choose>
                                <xsl:when test="$break_element_type = 'glue'">
                                    <xsl:value-of select="$break_element/@stretchability"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="0"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                        
                        <xsl:with-param name="z_prev">
                            <xsl:choose>
                                <xsl:when test="$break_element_type= 'glue'">
                                    <xsl:value-of select="$break_element/@shrinkability"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="0"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                        

                        <!-- The new 'previous' index in the branches will be the 'new_break' index -->
                        <xsl:with-param name="break_prev" select="$break_curr"/>
                        <xsl:with-param name="break_curr" select="-1"/>
                        

                    </xsl:call-template>                             
                </xsl:when>
            
                <xsl:otherwise>                            
                    <xsl:call-template name="calcBranch">
                        <xsl:with-param name="l_max" select="$l_max"/>
                        
                        <!-- one additional element -->
                        <xsl:with-param name="start_index" select="$start_index"/>
                        <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                                        
                        <!-- Pass l,y, z values -->
                        <xsl:with-param name="l_prev" select="$l_curr"/>
                        <xsl:with-param name="y_prev" select="$y_curr"/>
                        <xsl:with-param name="z_prev" select="$z_curr"/>
                         
                        <xsl:with-param name="break_prev" select="$break_prev"/>
                        <xsl:with-param name="break_curr">
                            <xsl:choose>
                                <!-- set value -->
                                <xsl:when test="$break_curr = -1 and ( $curr_element_break = 'optional'
                                        or $curr_element_break = 'required') "> 
                                        <xsl:value-of select="$stop_index"/>
                                </xsl:when>

                                <!-- value has been set & doesn't change -->
                                <xsl:otherwise>
                                    <xsl:value-of select="$break_curr"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                       
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>