<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>


<xsl:template match="document/paragraph" name="tokenize">
    <xsl:param name="text" select="normalize-space(.)"/>
    <xsl:param name="separator" select="' '"/>
    <xsl:param name="doc_width"/>
    <xsl:param name="doc_align"/>

    <!-- setglue width to font size of paragraph or document-->
    <xsl:param name="gluewidth">
        <xsl:choose>
        <xsl:when test="@font-size != ''">
            <xsl:copy-of select="@font-size * 0.5"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy-of select="$doc_width"/>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:param>
    
    <!-- same for align-->
    <xsl:param name="align">
        <xsl:choose>
        <xsl:when test="@align != ''">
            <xsl:value-of select="@align"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$doc_align"/>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:param>
    
    <xsl:choose>
        <xsl:when test="$align = 'justified'">
        <xsl:choose>
            <!-- last word doesn't contain any more spaces-->
            <xsl:when test="not(contains($text, $separator))">
                <box>
                    <xsl:variable name="word" select="$text"/>
                    <xsl:attribute name="width">
                        <xsl:copy-of select="string-length($word) * 12" />
                    </xsl:attribute>
                    <xsl:value-of select="$word"/>
                </box>
                <penalty>
                    <xsl:attribute name="penalty">INF</xsl:attribute>
                    <xsl:attribute name="break">prohibited</xsl:attribute>
                </penalty>
                <glue>
                    <xsl:attribute name="width">0</xsl:attribute>
                    <xsl:attribute name="stretchability">INF</xsl:attribute>
                    <xsl:attribute name="shrinkability">0</xsl:attribute>
                </glue>
                <penalty>
                    <xsl:attribute name="penalty">-INF</xsl:attribute>
                    <xsl:attribute name="break">required</xsl:attribute>
                </penalty>
            </xsl:when>       
            <xsl:otherwise>
                <box>
                    <xsl:variable name="word" select="normalize-space(substring-before($text, $separator))"/>
                    <xsl:attribute name="width">
                        <xsl:value-of select="string-length($word) * 12" />
                    </xsl:attribute>
                    <xsl:value-of select="$word"/>
                </box>
                <glue>
                    <xsl:attribute name="stretchability">18</xsl:attribute>
                    <xsl:attribute name="shrinkability">0</xsl:attribute>
                    <xsl:attribute name="width">
                        <xsl:value-of select="$gluewidth" />
                    </xsl:attribute>
                </glue>
                <xsl:call-template name="tokenize">
                    <xsl:with-param name="text" select="substring-after($text, $separator)"/>
                    <xsl:with-param name="doc_width" select="$doc_width"/>
                    <xsl:with-param name="doc_align" select="$doc_align"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:when>
        <xsl:when test="$align = 'centered'">
        <xsl:choose>
            <!-- last word doesn't contain any more spaces-->
            <xsl:when test="not(contains($text, $separator))">
                <glue>
                    <xsl:attribute name="width">0</xsl:attribute>
                    <xsl:attribute name="stretchability">18</xsl:attribute>
                    <xsl:attribute name="shrinkability">0</xsl:attribute>
                </glue>
                <box>
                    <xsl:variable name="word" select="$text"/>
                    <xsl:attribute name="width">
                        <xsl:copy-of select="string-length($word) * 12" />
                    </xsl:attribute>
                    <xsl:value-of select="$word"/>
                </box>

                <glue>
                    <xsl:attribute name="width">0</xsl:attribute>
                    <xsl:attribute name="stretchability">18</xsl:attribute>
                    <xsl:attribute name="shrinkability">0</xsl:attribute>
                </glue>
                <penalty>
                    <xsl:attribute name="penalty">-INF</xsl:attribute>
                    <xsl:attribute name="break">required</xsl:attribute>
                </penalty>
            </xsl:when>       
            <xsl:otherwise>
                <glue>
                    <xsl:attribute name="stretchability">18</xsl:attribute>
                    <xsl:attribute name="shrinkability">0</xsl:attribute>
                    <xsl:attribute name="width">0</xsl:attribute>
                </glue>
                
                <box>
                    <xsl:variable name="word" select="normalize-space(substring-before($text, $separator))"/>
                    <xsl:attribute name="width">
                        <xsl:copy-of select="string-length($word) * 12" />
                    </xsl:attribute>
                    <xsl:value-of select="$word"/>
                </box>
                <glue>
                    <xsl:attribute name="stretchability">18</xsl:attribute>
                    <xsl:attribute name="shrinkability">0</xsl:attribute>
                    <xsl:attribute name="width">0</xsl:attribute>
                </glue>
                <penalty>
                    <xsl:attribute name="penalty">0</xsl:attribute>
                    <xsl:attribute name="break">optional</xsl:attribute>
                </penalty>
                <glue>
                    <xsl:attribute name="stretchability">-36</xsl:attribute>
                    <xsl:attribute name="shrinkability">0</xsl:attribute>
                    <xsl:attribute name="width">0</xsl:attribute>
                </glue>
                <box>
                    <xsl:attribute name="width">0</xsl:attribute>
                </box>
                <penalty>
                    <xsl:attribute name="penalty">INF</xsl:attribute>
                    <xsl:attribute name="break">prohibited</xsl:attribute>
                </penalty>
                
                <!--recursion -->
                <xsl:call-template name="tokenize">
                    <xsl:with-param name="text" select="substring-after($text, $separator)"/>
                    <xsl:with-param name="doc_width" select="$doc_width"/>
                    <xsl:with-param name="doc_align" select="$doc_align"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="document">
    <document>
        <xsl:attribute name="align">
            <xsl:value-of select="@align"/>
        </xsl:attribute>
        <xsl:variable name="doc_align" select="@align"/>

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
            <xsl:attribute name="align">
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
        
        <xsl:call-template name="tokenize">
            <xsl:with-param name="doc_width" select="$doc_gluewidth"/>
            <xsl:with-param name="doc_align" select="$doc_align"/>
        </xsl:call-template>
        
        </paragraph>
    </xsl:for-each>

</document>
</xsl:template>
</xsl:stylesheet>