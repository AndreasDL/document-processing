<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- create path objects -->
<xsl:template match="paragraph">
    <xsl:variable name="goal_index" select="./branches/branch[last()]/@stop"/>
    
    <xsl:for-each select="./branches/branch[@previous = 0]">
        <xsl:call-template name="write_total_cost">
            <xsl:with-param name="cost_so_far" select="0"/>
            <xsl:with-param name="prev_index" select="0"/>
            <xsl:with-param name="curr_branch" select="."/>
            <xsl:with-param name="goal_index" select="$goal_index"/>
        </xsl:call-template>
    </xsl:for-each>

</xsl:template>

<xsl:template name="write_total_cost">
    <xsl:param name="cost_so_far"/>
    <xsl:param name="prev_index"/>
    <xsl:param name="curr_branch"/>
    <xsl:param name="goal_index"/>  

    <xsl:variable name="curr_index" select="$curr_branch/@stop"/>
    <xsl:variable name="curr_cost" select="$cost_so_far + $curr_branch/@cost"/>

    <!-- write -->
    <!--branch>
        <!- keep orig values ->
        <xsl:attribute name="cost">
            <xsl:value-of select="$curr_branch/@cost"/>
        </xsl:attribute>

        <xsl:attribute name="ratio">
            <xsl:value-of select="$curr_branch/@ratio"/>
        </xsl:attribute>

        <xsl:attribute name="start">
            <xsl:value-of select="$curr_branch/@start"/>
        </xsl:attribute>

        <xsl:attribute name="stop">
            <xsl:value-of select="$curr_branch/@stop"/>
        </xsl:attribute>

        <xsl:attribute name="previous">
            <xsl:value-of select="$curr_branch/@previous"/>
        </xsl:attribute>

        <!- add the cost for the path ->
        <xsl:attribute name="total_cost">
            <xsl:value-of select="$curr_cost"/>
        </xsl:attribute>
    </branch-->

    <!-- recusion -->
    <!--xsl:if test="$curr_index &lt; $goal_index">
        <xsl:for-each select="../branch[@previous = $curr_index]">
            <xsl:call-template name="write_total_cost">
                <xsl:with-param name="cost_so_far" select="$curr_cost"/>
                <xsl:with-param name="prev_index" select="$curr_index"/>
                <xsl:with-param name="curr_branch" select="."/>
                <xsl:with-param name="goal_index" select="$goal_index"/>
            </xsl:call-template>
        </xsl:for-each>

    </xsl:if-->
</xsl:template>

</xsl:stylesheet>