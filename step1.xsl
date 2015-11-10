<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- TODO calculate these variables as they are not static!-->
<xsl:variable name="stretch" select="18"/>
<xsl:variable name="shrink" select="0"/>
<!--xsl:variable name="doc_gluewidth" select="13"/-->

<xsl:template match="document/paragraph" name="tokenize">
    <xsl:param name="text" select="normalize-space(.)"/>
    <xsl:param name="separator" select="' '"/>
    <xsl:param name="doc_width"/>
    
    <xsl:param name="gluewidth">
        <xsl:choose>
        <xsl:when test="@font-size != ''">
            <xsl:copy-of select="@font-size * 0.5"/>
        </xsl:when>
        <xsl:otherwise>
            <!--xsl:copy-of select="$doc_width"/-->
            <xsl:copy-of select="$doc_width"/>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:param>

    <xsl:choose>
        <xsl:when test="not(contains($text, $separator))">
            <box>
                <xsl:variable name="word" select="$text"/>

                <xsl:attribute name="width">
                    <xsl:copy-of select="string-length($word) * 12" />
                </xsl:attribute>
                
                <xsl:value-of select="$word"/>

            </box>
        </xsl:when>       
        <xsl:otherwise>
            <box>
                <xsl:variable name="word" select="normalize-space(substring-before($text, $separator))"/>

                <xsl:attribute name="width">
                    <xsl:copy-of select="string-length($word) * 12" />
                </xsl:attribute>
                
                <xsl:value-of select="$word"/>

            </box>
            <glue>
                <xsl:attribute name="stretchability">
                    <xsl:copy-of select="$stretch" />
                </xsl:attribute>
                <xsl:attribute name="shrinkability">
                    <xsl:copy-of select="$shrink" />
                </xsl:attribute>
                <xsl:attribute name="width">
                    <xsl:value-of select="$gluewidth" />
                </xsl:attribute>
            </glue>

            <xsl:call-template name="tokenize">
                <xsl:with-param name="text" select="substring-after($text, $separator)"/>
                <xsl:with-param name="doc_width" select="$doc_width"/>
            </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="document">
    <document>
        <xsl:attribute name="align" match="@align">
            <xsl:value-of select="@align"/>
        </xsl:attribute>
        <xsl:attribute name="line-width">
            <xsl:value-of select="@line-width"/>
        </xsl:attribute>
        <xsl:attribute name="font-size">
            <xsl:value-of select="@font-size" />
        </xsl:attribute>
        <xsl:variable name="doc_gluewidth" select="@font-size * 0.5"/>

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
        
        <xsl:call-template name="tokenize" select=".">
            <xsl:with-param name="doc_width" select="$doc_gluewidth"/>
        </xsl:call-template>
        
        </paragraph>
    </xsl:for-each>

</document>
</xsl:template>
</xsl:stylesheet>