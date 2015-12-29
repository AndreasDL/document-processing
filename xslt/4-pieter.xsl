<?xml version="1.0" encoding="UTF-8"?>
<!-- Finally, the peacock can open its feathers.
                                                              o
                                                            o%
                                                           //
                                                      -="~\
                                                        ~\\\
                                                          \\\
                                                           \\\
                                                            );\
                                                           /|;;\
                                                      """;;;;;;;\
                                                ///"""""""";;;;;;\
                                    ___////+++++""""""""""""";;;@@\
                      __________///////++++++++++++++""""""""@@@@%)
           ....__/0)///0)//0)//0)/++////////++++++++++"""@@@%%%%%/
     ..- -0)/- - - - ////////////////+++++++/////+++++@@%%%%%%%/
      ..///- -0)- -0)///0)//0)///0)/////////+++++====@%%%%%%/
   ...0)....// - -/// - - -////////////+++++///"     \/\\//
      //../0) -0)///0)///0)///0)//++++/////          /  \/
      - /// - - - -///////////+++/////             _/   /
.-//..0).-/0) -0) -0) -0) -..                      /\  /
       ....... -/////////.                            /\_
            .0)..0)..
-->

<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- SVG document type declaration -->
<xsl:output method="xml" doctype-public="-//W3C//DTD SVG 1.0//EN" doctype-system="http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" media-type="image/svg" />
<xsl:variable name="doc_font_size" select="/document/@font-size" />

<!-- Copy machine: copies every element that doesn't matches another template -->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<!-- Transform the root element -->
<xsl:template match="/">
	<svg xmlns="http://www.w3.org/2000/svg">
		<xsl:attribute name="width">
			<xsl:value-of select="/document/@line-width"/>
		</xsl:attribute>
		
		<!-- Get the height of the total svg -->
		<xsl:variable name="height">
			<xsl:call-template name="getHeight"/>
		</xsl:variable>
		<xsl:attribute name="height">
			<xsl:value-of select="$height"/>
		</xsl:attribute>
		
		<!-- Create a nice black border around the svg -->
		<rect style="fill:none;stroke-width:1;stroke:rgb(0,0,0);">
			<xsl:attribute name="width">
				<xsl:value-of select="/document/@line-width"/>
			</xsl:attribute>			
			<xsl:attribute name="height">
				<xsl:value-of select="$height"/>
			</xsl:attribute>
		</rect>
		
		<!-- Add the paragraphs one by one as g elements -->
		<xsl:call-template name="addG"/>
	</svg>
</xsl:template>

<!-- This template recursively adds paragraphs as g elements. Current is the position of the paragraph
to be added, offset_height is the height offset of the paragraph. After a paragraph is added, the template
recursively calls itself with an incremented current and an adapted offset, until no more paragraphs are
available -->
<xsl:template name="addG">
	<xsl:param name="current" select="1"/>
	<xsl:param name="offset_height" select="0"/>
	
	<!-- Check whether there is a paragraph to add -->
    <xsl:if test="$current &lt;= count(/document/*)">
		<xsl:variable name="curParagraph" select="/document/paragraph[$current]" />
		
		<!-- Get the alignment and font size for the current paragraph -->
		<xsl:variable name="align">
			<xsl:choose>
				<xsl:when test="$curParagraph/@align">
					<xsl:value-of select="$curParagraph/@align"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="/document/@align"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="font_size">
			<xsl:choose>
				<xsl:when test="$curParagraph/@font-size">
					<xsl:value-of select="$curParagraph/@font-size"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$doc_font_size"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- Add half of the font height to the height offset for all paragraphs, except the first one -->
		<xsl:variable name="current_offset_height">
			<xsl:choose>
				<xsl:when test="$current = 1">
					<xsl:value-of select="0"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$offset_height + $font_size * 0.5"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- Add a horizontal offset if the paragraphs alignment is centered or justified and the paragraph line width
		is different from the document line width (to nicely center the paragraph). -->
		<xsl:variable name="startX">
			<xsl:choose>
				<xsl:when test="($align = 'centered' or $align = 'justified') and ($curParagraph/@line-width)">
					<xsl:value-of select="(/document/@line-width -$curParagraph/@line-width) *0.5"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<!-- Now, add the paragraph as a g element -->
		<g>
			<xsl:attribute name="font-family">
				<xsl:value-of select="'monospace'"/>
			</xsl:attribute>
			<xsl:attribute name="style">
				<xsl:value-of select="concat('font-size:', $font_size, ';')"/>
			</xsl:attribute>
			<!-- Add each of the lines of the paragraph --> 
			<xsl:for-each select="$curParagraph/line[*]">
				<text>
					<!-- Add each of the words on the current line -->
					<xsl:call-template name="addSpans">
						<xsl:with-param name="current" select="1"/>
						<xsl:with-param name="line" select="."/>
						<xsl:with-param name="x" select="$startX"/>
						<xsl:with-param name="y" select="$current_offset_height + (count(preceding-sibling::*)+1) * $font_size"/>
					</xsl:call-template>
				</text>
			</xsl:for-each>		
		</g>
		
		<!-- Recursion. Add another half height of the font size to the height offset, next to the increase because of the new lines. -->
		<xsl:call-template name="addG">
			<xsl:with-param name="current" select="$current+1"/>
			<xsl:with-param name="offset_height" select="$current_offset_height + $font_size * count($curParagraph/line) + $font_size*0.5"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- This template recursively add elements of a line as g span elements. Current is the position of the element to be added in the line,
x is the horizontal offset of the word and y is the vertical offset. After an element is added, the template recursively calls itself with
an incremented current and an adapted horizontal offset, until no more element are available. -->
<xsl:template name="addSpans">
	<xsl:param name="current"/>
	<xsl:param name="line"/>
	<xsl:param name="x"/>
	<xsl:param name="y"/>
	
	<!-- Check whether there is an element to add to the g -->
    <xsl:if test="$current &lt;= count($line/*)">
		<!-- There is an element! -->
		<xsl:variable name="element" select="$line/*[$current]"/>
		
		<!-- If it is a box with content, add it as a span -->
		<xsl:if test="name($element) = 'box' and not($element/@width = 0)">
			<tspan>
				<xsl:attribute name="x">
					<xsl:value-of select="$x"/>
				</xsl:attribute>
				<xsl:attribute name="y">
					<xsl:value-of select="$y"/>
				</xsl:attribute>	
				<xsl:attribute name="textLength">
					<xsl:value-of select="$element/@width"/>
				</xsl:attribute>
				<xsl:value-of select="$element/node()"/>
			</tspan>
		</xsl:if>

		<!-- Calculate the new horizontal offset -->
		<xsl:variable name="new_x">
			<xsl:choose>
				<xsl:when test="name($element) = 'glue'">
					<xsl:choose>
						<xsl:when test="$line/@ratio &gt;= 0">
							<xsl:value-of select="$x + $element/@width + number($element/@stretchability) * number($line/@ratio)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$x + $element/@width + number($element/@shrinkability) * $line/@ratio"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$x + $element/@width"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- Recursion -->
		<xsl:call-template name="addSpans">
			<xsl:with-param name="current" select="$current+1"/>
			<xsl:with-param name="line" select="$line"/>
			<xsl:with-param name="x" select="$new_x"/>
			<xsl:with-param name="y" select="$y"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- This template calculates (and writes) the total height of the svg document.
This total height equals the sum of the heights of all paragraphs. Current is the
position of the paragraph of which the height is calculated. This height is added
to the parameter, wafter which the function recursively calls itself until the heights
of all paragraphs are summed. -->
<xsl:template name="getHeight">
	<xsl:param name="current" select="1"/>
	<xsl:param name="height" select="0"/>
	
	<!-- Check whether there is a paragraph to calculate the height of -->
    <xsl:choose>
        <xsl:when test="$current &lt;= count(/document/*)">
			<!-- There is a paragraph. Determine the font size. -->
			<xsl:variable name="curParagraph" select="/document/paragraph[$current]" />
			<xsl:variable name="font_size">
				<xsl:choose>
					<xsl:when test="$curParagraph/@font-size">
						<xsl:value-of select="$curParagraph/@font-size"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$doc_font_size"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<!-- Calculate the height of the paragraph and add it to the total height. For
			all paragraphs, except the first one, this is the number of lines plus one times
			the font size. For the last one, this is the number of lines plus a half times the
			font size (no extra space above the first paragraph). -->
			<xsl:variable name="current_height">
				<xsl:choose>
					<xsl:when test="$current = 1">
						<xsl:value-of select="$height + $font_size * (0.5 + count($curParagraph/line))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$height + $font_size * (1 + count($curParagraph/line))"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<!-- Recursion -->
			<xsl:call-template name="getHeight">
				<xsl:with-param name="current" select="$current+1"/>
				<xsl:with-param name="height" select="$current_height"/>
			</xsl:call-template>
		</xsl:when>
        <xsl:otherwise>
			<!-- There are no paragraphs left. Return the calculated height. -->
            <xsl:value-of select="$height"/>
        </xsl:otherwise>
    </xsl:choose>	
</xsl:template>

</xsl:transform>