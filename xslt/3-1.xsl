<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- create path objects -->
<xsl:template match="paragraph">
    <xsl:variable name="stop_index" select="./branches/branch[last()]/@stop"/>
    <xsl:variable name="start_index" select="1"/>
    
    <xsl:call-template name="write_total_cost">
        <xsl:with-param name="cost_so_far" select="0"/>
        <xsl:with-param name="prev_index" select="0"/>
        <xsl:with-param name="curr_index" select="$start_index"/>
        <xsl:with-param name="stop_index" select="$stop_index"/>
    </xsl:call-template>

</xsl:template>

<xsl:template name="write_total_cost">
    <xsl:param name="cost_so_far"/>
    <xsl:param name="prev_index"/>
    <xsl:param name="curr_index"/>
    <xsl:param name="stop_index"/>    

    <xsl:variable name="curr_branch" select="./branches/*[@start = $curr_index]"/>
    
    <xsl:variable name="curr_cost">
        <xsl:choose>
            <xsl:when test="$prev_index = 0">
                <xsl:value-of select="$curr_branch/@cost"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$cost_so_far + $curr_branch/@cost"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- write -->
    <branch>
        <!-- keep orig values -->
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

        <!-- add the cost for the path -->
        <xsl:attribute name="total_cost">
            <xsl:value-of select="$curr_cost"/>
        </xsl:attribute>
    </branch>

</xsl:template>

</xsl:stylesheet>