<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<xsl:template name="branches">
    <xsl:param name="line-width"/>

    <xsl:copy-of select="."/>
    
    <xsl:foreach select="box">
        <xsl:variable name="first_width" select="@width"/>
        <xsl:variable name="glue" select="next()"/>

        <!--xsl:copy-of select="$glue"/-->
    </xsl:foreach>

</xsl:template>

<xsl:template match="document">
    <document>
        <xsl:attribute name="align" match="@align">
            <xsl:value-of select="@align"/>
        </xsl:attribute>
        <xsl:attribute name="line-width">
            <xsl:value-of select="@line-width"/>
        </xsl:attribute>
        <xsl:variable name="doc_linewidth" select="@line-width"/>
        <xsl:attribute name="font-size">
            <xsl:value-of select="@font-size" />
        </xsl:attribute>

    <xsl:for-each select="paragraph">
        <paragraph>
        <xsl:if test="@align != ''">
            <xsl:attribute name="align" match="@align">
                <xsl:value-of select="@align"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="@line-width != ''">
            <xsl:attribute name="line-width">
                <xsl:value-of select="@line-width"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="@font-size != ''">
            <xsl:attribute name="font-size">
                <xsl:value-of select="@font-size" />
            </xsl:attribute>
        </xsl:if>

        <content>
            <xsl:copy-of select="*"/>
        </content>
        
        <branches>
            <xsl:call-template name="branches" select=".">
                <xsl:with-param name="line-width">
                    <xsl:choose>
                        <xsl:when test="@line-width != ''">
                            <xsl:value-of select="@line-width"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@doc_linewidth"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </branches>

        </paragraph>
    </xsl:for-each>
</document>
</xsl:template>
</xsl:stylesheet>