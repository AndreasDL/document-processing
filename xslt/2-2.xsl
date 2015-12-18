<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- step 2, please run the preprocessing step in 2-1.xsl first -->

<!-- Fair warning: looking at this template might cause permanent eye damage -->
<xsl:template name="calcBranch">
    <xsl:param name="l_max"/> <!-- line width or max width that can be places on one line -->
    <xsl:param name="start_index"/>
    <xsl:param name="stop_index"/>
    <xsl:param name="l_prev"/>
    <xsl:param name="y_prev"/>
    <xsl:param name="z_prev"/>

    <!-- init some basic params, readability++ -->
    <xsl:variable name="curr_element" select="./*[position() == $stop_index]"/>
    <xsl:variable name="curr_element_type" select="name($curr_element)" />
    
    <!-- new l, y, z values -->
    <xsl:choose>
        <!-- things only change when the current element type is glue -->
        <xsl:when test="$curr_element_type = 'glue'">

            <xsl:variable name="l_curr">
                <xsl:value-of select="$l_prev + $curr_element/@width"/>
            </xsl:variable>
            
            <xsl:variable name="y_curr">
                <xls:choose>
                    <!-- infinity is only 'kinda' supported -->
                    <xsl:when test="$curr_element/@stretchability = 'INF'">
                        <xsl:value-of select="INF"/>
                    </xsl:when>

                    <xsl:when test="$curr_element/@stretchability = '-INF'">
                        <xsl:value-of select="-INF"/>
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:value-of select="$y_prev + $curr_element/@stretchability"/>
                    </xsl:otherwise>
                </xls:choose>
            </xsl:variable>

            <xsl:variable name="z_curr">
                <xsl:value-of select="$z_prev + $curr_element/@shrinkability"/>
            </xsl:variable>
        </xsl:when>
        
        <!-- nothing changes -->
        <xsl:otherwise>    
            <xsl:variable name="l_curr">
                <xsl:value-of select="$l_prev"/>
            </xsl:variable>

            <xsl:variable name="y_curr">
                <xsl:value-of select="$y_prev"/>
            </xsl:variable>

            <xsl:variable name="z_curr">
                <xsl:value-of select="$z_prev"/>
            </xsl:variable>
        </xsl:otherwise>
    </xsl:choose>

    <!-- fix ratio -->
    <xsl:variable name="ratio">
        <xsl:choose>

            <!-- l_curr == l-max , perfect fit!-->
            <xsl:when test="$l_max = $l_curr">
                <xsl:value-of select="0"/>
            </xsl:when>

            <!-- l_curr < l_max stretch!-->
            <xsl:when test="$l_max > $l_curr">
                <!-- again infinity is not supported, but that is what you get if you work with outdated stuffs -->
                <xsl:choose>
                    <xsl:when test="$y_curr = 'INF' or $y_curr = '-INF'">
                        <xsl:value-of select="0"/>
                    </xsl:when>

                    <xsl:when test="$y_curr > 0">
                        <xsl:value-of select="($l_max - $l_curr) div $y_curr"/>
                    </xsl:when>

                    <xsl:otherwise>
                        <!-- yj <= 0 -> ratio undefined-->
                        <xsl:value-of select="NaN"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- l-curr > l_max shrink!-->
            <!-- never split on negative ratio => set to -1 for simplicity -->
            <xsl:when test="$l_curr > $l_max">
                <xsl:value-of select="-1"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>

    <!-- fix the bills -->
    <xsl:variable name="cost">
        <xsl:choose>
            <!--
            <xsl:when test="$ratio = 0 or $curr_element/@penalty = '-INF'">
                <!-- setting the cost to -INF will result in the select of a random branch at the end of the paragraph, since x - INF = y - INF = -INF ->
                <xsl:value-of select="0"/>
            </xsl:when>-->

            <!-- cost is infinity -->
            <xsl:when test="$ratio = 'INF' or $ratio = '-INF' or $ratio = 'NaN' or -1 > $ratio">
                <xsl:value-of select="'INF'"/>
            </xsl:when> 

            <xsl:otherwise>
                <xsl:value-of select="round(100 * $ratio*$ratio*$ratio)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- spam to output -->
    <xsl:if test="$ratio != 'NaN' and $ratio < 0 and ( $curr_element/@break = 'required' or $curr_element/@break = 'optional' ) and $start_index = $stop_index ">
        
        <branch>
            <xsl:attribute name="ratio">
                <xsl:value-of select="$ratio"/>
            </xsl:attribute>

            <xsl:attribute name="cost">
                <xsl:choose>
                    <xsl:when test="$ratio = 0">
                        <xsl:value-of select="0"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="format-number($cost,'#')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>

            <xsl:attribute name="start">
                <xsl:value-of select="$start_index"/>
            </xsl:attribute>

            <xsl:attribute name="end">
                <xsl:value-of select="$stop_index"/>
            </xsl:attribute>
        </branch>
    </xsl:if>

    <xsl:choose>
        <xsl:when test="0 > $ratio ">
    </xsl:choose>

</xsl:template>

<xsl:template match="document/paragraph">
    <xsl:param name="doc_line_width"/>

    <!-- fix the content part -->
    <xsl:copy>
        <!-- attribute fix one-liner -->
        <xsl:apply-templates select="@*"/>

        <!--fix content == copy of original data -->
        <content>
            <xsl:copy-of select="current()/*"/>
        </content>

        <!-- fix the branches -->
        
        <branches>
            <xsl:call-template name="calcBranch">
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

                <!--line runs from start_index until the stop_index-->
                <xsl:with-param name="start_index" select="1"/>
                <xsl:with-param name="stop_index" select="1"/>

                <!-- too sum the elements -->
                <xsl:with-param name="l_prev" select="0"/>
                <xsl:with-param name="y_prev" select="0"/>
                <xsl:with-param name="z_prev" select="0"/>

            </xsl:call-template>
        </branches>

    </xsl:copy>
</xsl:template>

<xsl:template match="document|@*">
    <xsl:variable name="doc_align" select="@align"/>
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates select="paragraph">
            <xsl:variable name="doc_line_width" select="@line-width"/>
        </xsl:apply-templates>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>