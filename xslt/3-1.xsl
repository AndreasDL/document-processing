<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- create path objects -->
<xsl:template match="paragraph">

</xsl:template>

<xsl:template name="find_path">
    <xsl:param name="curr_lowest_cost"/>
    <xsl:param name="path"/>
    <xsl:param name="start_index"/>
    <xsl:param name="stop_index"/>


</xsl:template>

<xsl:template name="min">
    <xsl:param name="a"/>
    <xsl:param name="b"/>

    <xsl:choose>
        <xsl:when test="$a > $b">
            <xsl:value-of select="$b"/>
        </xsl:when>
        <xsl:othwise>
            <xsl:value-of select="$a"/>
        </xsl:othwise>
    </xsl:choose>
</xsl:template>
</xsl:stylesheet>