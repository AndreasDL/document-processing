<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<xsl:template name="calcBranch">
    <xsl:param name="start_index"/>
    <xsl:param name="stop_index"/>
    <xsl:param name="l_max"/>
    <xsl:param name="l_prev"/>

    <!--verify input-->
    <!--<xsl:value-of select="$start_index"/>
    <xsl:value-of select="$stop_index"/> 
    <xsl:value-of select="$l_max"/>-->

    <!-- get values -->
    <xsl:variable name="l_curr" select="sum( ./*[ position() >= $start_index and $stop_index > position() ]/@width )"/>

    <!-- if current item is a glue element => continue -->
    <xsl:choose>
    <xsl:when test="name(./*[ position() = $stop_index]) = glue">
        <!-- recusion -->
        <xsl:call-template name="calcBranch">
            <xsl:with-param name="start_index" select="$start_index"/>
            <xsl:with-param name="stop_index" select="$stop_index + 1"/>
            
            <xsl:with-param name="l_max" select="$l_max"/>
            <xsl:with-param name="l_prev" select="$l_curr"/>
        </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
        
        <!-- exceeding l_max ? -->
        <xsl:choose>
            <xsl:when test="$l_curr > $l_max">
                
                <xsl:variable name="last_word" select="./*[ position = $stop_index]"/>

                <!--remove last glue-->

                <!-- get ratio -->
                <xsl:variable name="y_curr" select="sum( ./*[ position() >= $start_index and $stop_index > position() ]/@stretchability )"/>
                
                <xsl:variable name="z_curr" select="sum( ./*[ position() >= $start_index and $stop_index > position() ]/@shrinkability )"/>
                
                <xsl:variable name="ratio">
                    <xsl:choose>
                        <xsl:when test="$l_max = $l_prev">
                            <xsl:value-of select="0"/>
                        </xsl:when>
                        <xsl:when test="$l_curr > $l_prev">
                            <xsl:value-of select="($l_max - $l_prev) div $y_curr"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="($l_max - $l_prev) div $z_curr"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="abs_ratio">
                    <xsl:value-of select="$ratio*($ratio >=0) - $ratio*($ratio &lt; 0)"/>
                </xsl:variable>

                <xsl:variable name="penalty">
                    <xsl:choose>
                        <xsl:when test="ratio > -1">
                            <xsl:value-of select="floor(100 * $abs_ratio*$abs_ratio*$abs_ratio + 0.5)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="1 div 0"/> <!--infinity-->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- only a branch when the penalty is below infinity
                <xsl:choose>
                <xsl:when test="0 > $penalty">-->
                    <branch>
                        <xsl:attribute name="cost">
                            <xsl:value-of select="$penalty"/>
                        </xsl:attribute>
                        <xsl:attribute name="ratio">
                            <xsl:value-of select="$ratio"/>
                        </xsl:attribute>
                    </branch>
                <!--</xsl:when>
                </xsl:choose>-->

                <!-- heap size too big ->
                <xsl:call-template name="calcBranch">
                    <xsl:with-param name="start_index" select="$stop_index + 1"/>
                    <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                    
                    <xsl:with-param name="l_max" select="$l_max"/>
                    <xsl:with-param name="l_prev" select="0"/>
                </xsl:call-template>-->

            </xsl:when>
            
            <xsl:otherwise>
                <!-- recusion, nothing happens -->
                <xsl:call-template name="calcBranch">
                    <xsl:with-param name="start_index" select="$start_index"/>
                    <xsl:with-param name="stop_index" select="$stop_index + 1"/>
                    
                    <xsl:with-param name="l_max" select="$l_max"/>
                    <xsl:with-param name="l_prev" select="$l_curr"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:otherwise>
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
        <xsl:variable name="doc_line_width" select="@line-width"/>

        
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
            
            <!-- fix the content part ->    
            <content>
                <xsl:copy-of select="current()/*"/>
            </content>-->

            <!-- branches -->
            <branches>
                <xsl:call-template name="calcBranch">
                    <xsl:with-param name="start_index" select="1"/>
                    <xsl:with-param name="stop_index" select="1"/>
                    
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

                    <xsl:with-param name="l_prev" select="0"/>
                    
                </xsl:call-template>
            </branches>
        </paragraph>
    </xsl:for-each>

    </document>
</xsl:template>
</xsl:stylesheet>