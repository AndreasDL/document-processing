<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" indent="yes" doctype-public="-//W3C//DTD SVG 1.0//EN" doctype-system="http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" media-type="image/svg" />

<!-- the lion king approves with the result :D

             ,%%%%%%%%,
           ,%%/\%%%%/\%%
          ,%%%\c "" J/%%%
 %.       %%%%/ o  o \%%%
 `%%.     %%%%    _  |%%%
  `%%     `%%%%(__Y__)%%'
  //       ;%%%%`\-/%%%'
 ((       /  `%%%%%%%'
  \\    .'          |
   \\  /       \  | |
    \\/         ) | |
 jgs \         /_ | |__
     (___________)))))))

-->
<xsl:template name="getHeightRecursion">
    <xsl:param name="prev_height"/>
    <xsl:param name="index" />

    <!-- get paragraph -->
    <xsl:variable name="curr_paragraph" select="/document/paragraph[position() = $index]"/>

    <!-- font-size overriden ? -->
    <xsl:variable name="font_size">
        <xsl:choose>
            <xsl:when test="$curr_paragraph/@font-size != ''">
                <xsl:value-of select="$curr_paragraph/@font-size"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="/document/@font-size"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- get lines in paragraph +1 for interspacing-->
    <xsl:variable name="line_count" select="count($curr_paragraph/line) + 1"/>
    
    <!-- what height for this paragraph ? -->
    <xsl:variable name="curr_height">
        <xsl:choose>
            <xsl:when test="$index = 1">
                <xsl:value-of select="$font_size * $line_count - ($font_size*1.5)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$font_size * $line_count"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- sum it together -->
    <xsl:variable name="new_height" select="$prev_height + $curr_height"/>

    <!-- recursion -->
    <xsl:variable name="paragraph_count" select="count(/document/paragraph[*])"/>
    <xsl:choose>
        <xsl:when test="$paragraph_count > $index">
            <xsl:call-template name="getHeightRecursion">
                <xsl:with-param name="prev_height" select="$new_height" />
                <xsl:with-param name="index" select="$index + 1" />
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <!-- return statement -->
            <xsl:value-of select="$new_height"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="document">

    <!-- get height -->
    <xsl:variable name="height">
        <xsl:call-template name="getHeightRecursion">
            <xsl:with-param name="index" select="0"/>
            <xsl:with-param name="prev_height" select="0"/>
        </xsl:call-template>
    </xsl:variable>

    <!-- fix the declaration -->
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <!-- hardcoded from example -->
        <xsl:attribute name="preserveAspectRatio">xMidYMid meet</xsl:attribute>
        <xsl:attribute name="zoomAndPan">magnify</xsl:attribute>
        <xsl:attribute name="version">1.0</xsl:attribute>
        <xsl:attribute name="contentScriptType">text/ecmascript</xsl:attribute>
        <xsl:attribute name="contentStyleType">text/css</xsl:attribute>
        
        <xsl:attribute name="width">
            <xsl:value-of select="/document/@line-width"/>
        </xsl:attribute>
        
        <xsl:attribute name="height">
            <xsl:value-of select="$height"/>
        </xsl:attribute>

        <!--rect-->
        <rect style="fill:none;stroke-width:1;stroke:rgb(0,0,0);">            
            <xsl:attribute name="height">
                <xsl:value-of select="$height"/>
            </xsl:attribute>
            <xsl:attribute name="width">
                <xsl:value-of select="/document/@line-width"/>
            </xsl:attribute>
        </rect>

        <!--start converting -->
        <xsl:call-template name="convertPara">
            <xsl:with-param name="index" select="1"/>
            <xsl:with-param name="y_para" select="0"/>
        </xsl:call-template>
    </svg>
</xsl:template>

<xsl:template name="convertPara">
    <xsl:param name="index"/>
    <xsl:param name="y_para"/>

    <!-- get paragraph -->
    <xsl:variable name="curr_paragraph" select="/document/paragraph[position() = $index]"/>
    
    <!-- font-size overriden ? -->
    <xsl:variable name="font_size">
        <xsl:choose>
            <xsl:when test="$curr_paragraph/@font-size != ''">
                <xsl:value-of select="$curr_paragraph/@font-size"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="/document/@font-size"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- fix y -->
    <xsl:variable name="y_new">
        <xsl:choose>
            <xsl:when test="$index = 1">
                <xsl:value-of select="0"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$y_para + $font_size * 0.5 "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <g font-family="monospace">
        <xsl:attribute name="style">
            <xsl:value-of select="concat('font-size:' , $font_size , ';')"/>
        </xsl:attribute>
    
        <!-- convert the lines -->
        <xsl:for-each select="$curr_paragraph/line">
            <text>
                <xsl:call-template name="convertLine">
                    <xsl:with-param name="x_curr" select="0"/>
                    <xsl:with-param name="y" select="$y_new + (count(preceding-sibling::*)+1) * $font_size "/>
                    <xsl:with-param name="index" select="1"/>
                    <xsl:with-param name="line_count" select="count(./*)"/>
                </xsl:call-template>
            </text>
        </xsl:for-each>
    </g>

    <!-- recursion -->
    <xsl:variable name="para_count" select="count(/document/paragraph[*])"/>
    <xsl:if test="$para_count > $index">
        <xsl:call-template name="convertPara">
            <xsl:with-param name="index" select="$index + 1"/>
            <xsl:with-param name="y_para" select="$y_para + (count($curr_paragraph/line[*]) * $font_size) + $font_size * 0.5"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="convertLine">
    <xsl:param name="x_curr"/>
    <xsl:param name="y"/>
    <xsl:param name="index"/>
    <xsl:param name="line_count"/>

    <xsl:variable name="ratio" select="@ratio"/>
    <xsl:variable name="curr_element" select="./*[position() = $index]"/>
    <xsl:variable name="curr_element_type" select="name($curr_element)"/>
    <xsl:variable name="curr_element_width" select="$curr_element/@width"/>

    <!-- only write output when the element is text-->
    <xsl:if test="$curr_element_type = 'box' and $curr_element_width > 0">
        <tspan>
            <xsl:attribute name="textLength">
                <xsl:value-of select="$curr_element_width"/>
            </xsl:attribute>

            <!-- position -->
            <xsl:attribute name="x">
                <xsl:value-of select="$x_curr"/>
            </xsl:attribute>
            
            <xsl:attribute name="y">
                <xsl:value-of select="$y"/>
            </xsl:attribute>

            <!-- content -->
            <xsl:value-of select="$curr_element/node()"/>
        </tspan>
    </xsl:if>

    <!-- recursion -->
    <xsl:variable name="x_new">
        <xsl:choose>
            <xsl:when test="$curr_element_type = 'glue'">
                <xsl:value-of select="$x_curr + $curr_element_width + $curr_element/@stretchability * $ratio"/>
            </xsl:when>
            <xsl:when test="$curr_element_type = 'box'">
                <xsl:value-of select="$x_curr + $curr_element_width"/>
            </xsl:when>
            <!-- ignore penalty elements -->
            <xsl:otherwise>
                <xsl:value-of select="$x_curr"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!--xsl:value-of select="$x_new"/>
    <xsl:text>&#xa;</xsl:text-->

    <xsl:if test="$line_count > $index">
        <xsl:call-template name="convertLine">
            <xsl:with-param name="y" select="$y"/>
            <xsl:with-param name="line_count" select="$line_count"/>
            <xsl:with-param name="index" select="$index + 1"/>
            <xsl:with-param name="x_curr" select="$x_new"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>