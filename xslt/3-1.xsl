<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- Copy machine: copies every element that doesn't match another template -->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*[not(name(.) = 'index')]|node()"/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>