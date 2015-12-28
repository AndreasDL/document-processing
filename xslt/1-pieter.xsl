<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="UTF-8"/>
<xsl:variable name="doc_font_size" select="/document/@font-size" />
<xsl:variable name="doc_align" select="/document/@align" />

<!-- The raccoon cleans his food.
                   __        .-.
               .-"` .`'.    /\\|
       _(\-/)_" ,  .   ,\  /\\\/
      {(#b^d#)} .   ./,  |/\\\/
      `-.(Y).-`  ,  |  , |\.-`
           /~/,_/~~~\,__.-`
          ////~    // ~\\
        ==`==`   ==`   ==`
-->

<!-- Copy machine: copies every element that doesn't matches another template -->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<!-- Transform the paragraphs -->
<xsl:template match="paragraph">
    <xsl:copy>
		<!-- Send paragraph attributes to the copy machine -->
        <xsl:apply-templates select="@*"/>
		
		<!-- Determine font size, character width, nominal glue width and alignment for this paragraph -->
        <xsl:variable name="font_size">
            <xsl:choose>
                <xsl:when test="@font-size">
                    <xsl:value-of select="@font-size"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$doc_font_size"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		<xsl:variable name="character_width" select="$font_size * 0.5" />
		<xsl:variable name="nominal_glue_width" select="$font_size * 0.5" />
		<xsl:variable name="align">
            <xsl:choose>
                <xsl:when test="@align">
                    <xsl:value-of select="@align"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$doc_align"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<!-- Now convert the paragraph according to it's alignment -->
        <xsl:choose>
            <xsl:when test="$align='justified'">
                <xsl:call-template name="recurse_justified">
                    <xsl:with-param name="text" select="normalize-space(.)"/> <!-- normalize-space removes the trailing and ending spaces of the paragraph --> 
                    <xsl:with-param name="character_width" select="$character_width"/>
                    <xsl:with-param name="nominal_glue_width" select="$nominal_glue_width"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$align='centered'">
                <xsl:call-template name="recurse_centered">
                    <xsl:with-param name="text" select="normalize-space(.)"/>
                    <xsl:with-param name="character_width" select="$character_width"/>
                    <xsl:with-param name="nominal_glue_width" select="$nominal_glue_width"/>
                </xsl:call-template>
            </xsl:when>
			<xsl:otherwise>
                <xsl:call-template name="recurse_ragged">
                    <xsl:with-param name="text" select="normalize-space(.)"/>
                    <xsl:with-param name="character_width" select="$character_width"/>
                    <xsl:with-param name="nominal_glue_width" select="$nominal_glue_width"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:copy>
</xsl:template>

<!-- This template outputs the correct elements (boxes, glues,...) for a text with justified alignment.
Each call converts the first word of given text in the corresponding sequence of elements.
After this, the converted word is stripped from the text and the function recursively calls itself
until only one word is available, after which an ending sequence of elements is added.-->
<xsl:template name="recurse_justified">
	<xsl:param name="text"/> <!-- The text of the paragraph -->
	<xsl:param name="character_width"/>
	<xsl:param name="nominal_glue_width"/>
	
	<!-- Determine whether there is only one word left. -->
	<xsl:choose>
        <xsl:when test="contains($text, ' ')">
		    <!-- There are multiple words left to be added. For justified alignment this means adding a box with the word
			and adding glue with width nominal glue width and stretchability 1.5 times the nominal glue width. -->
    	    <xsl:call-template name="add_box">
	            <xsl:with-param name="word" select="substring-before($text, ' ')"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
	        </xsl:call-template>
			<xsl:call-template name="add_standard_glue">
				<xsl:with-param name="nominal_width" select="$nominal_glue_width"/>
			</xsl:call-template>
			
			<!-- Recursion -->
    	    <xsl:call-template name="recurse_justified">
	            <xsl:with-param name="text" select="substring-after($text, ' ')"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
		        <xsl:with-param name="nominal_glue_width" select="$nominal_glue_width"/>
	        </xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
		    <!-- Only one word is left in the text. Add the word in a box, avoid a breakpoint after this
			box by adding a prohibited penalty, add infinitely stretchable glue and add a required breakpoint. -->
    	    <xsl:call-template name="add_box">
	            <xsl:with-param name="word" select="$text"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
	        </xsl:call-template>
			<xsl:call-template name="add_prohibited_penalty" />
			<xsl:call-template name="add_weak_glue" />
			<xsl:call-template name="add_required_penalty" />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- This template outputs the correct elements (boxes, glues,...) for a text with centered alignment.
Each call converts the first word of given text in the corresponding sequence of elements.
After this, the converted word is stripped from the text and the function recursively calls itself
until only one word is available, after which an ending sequence of elements is added.-->
<xsl:template name="recurse_centered">
	<xsl:param name="text"/> <!-- The text of the paragraph -->
	<xsl:param name="character_width"/>
	<xsl:param name="nominal_glue_width"/>
	
	<!-- Determine whether there is only one word left. -->
	<xsl:choose>
        <xsl:when test="contains($text, ' ')">
		    <!-- There are multiple words left to be added. For centered alignment this means adding glue with width 0
			and stretchability equal to 1.5 times the nominal glue width, adding a box with the word, adding glue with width 0
			and stretchability equal to 1.5 times the nominal glue width, adding a penalty with cost zero, adding glue with a
			width equal to the nominal glue width and stretchability -3 times the nominal glue width (thus cancelling out the
			stretchabilities of the preceding, and following glues), adding an empty box and adding a penaly that prohibits
			breaking after the empty box. -->
			<xsl:call-template name="add_positive_glue">
				<xsl:with-param name="nominal_width" select="$nominal_glue_width"/>
			</xsl:call-template>
    	    <xsl:call-template name="add_box">
	            <xsl:with-param name="word" select="substring-before($text, ' ')"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
	        </xsl:call-template>
			<xsl:call-template name="add_positive_glue">
				<xsl:with-param name="nominal_width" select="$nominal_glue_width"/>
			</xsl:call-template>
			<xsl:call-template name="add_optional_penalty"/>
			<xsl:call-template name="add_double_negative_glue">
				<xsl:with-param name="nominal_width" select="$nominal_glue_width"/>
			</xsl:call-template>
    	    <xsl:call-template name="add_box">
	            <xsl:with-param name="word" select=""/>
		        <xsl:with-param name="character_width" select="$character_width"/>
	        </xsl:call-template>
			<xsl:call-template name="add_prohibited_penalty"/>
			
			<!-- Recursion -->
    	    <xsl:call-template name="recurse_centered">
	            <xsl:with-param name="text" select="substring-after($text, ' ')"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
		        <xsl:with-param name="nominal_glue_width" select="$nominal_glue_width"/>
	        </xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
		    <!-- Only one word is left in the text. Add glue with width 0 and stretchability equal to 1.5 times the nominal glue width,
			add a box with the word, add glue with width 0 and stretchability equal to 1.5 times the nominal glue width
			and enforce a break point by adding a required penalty. -->
			<xsl:call-template name="add_positive_glue">
				<xsl:with-param name="nominal_width" select="$nominal_glue_width"/>
			</xsl:call-template>
    	    <xsl:call-template name="add_box">
	            <xsl:with-param name="word" select="$text"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
	        </xsl:call-template>
			<xsl:call-template name="add_positive_glue">
				<xsl:with-param name="nominal_width" select="$nominal_glue_width"/>
			</xsl:call-template>
			<xsl:call-template name="add_required_penalty"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- This template outputs the correct elements (boxes, glues,...) for a text with ragged alignment.
Each call converts the first word of given text in the corresponding sequence of elements.
After this, the converted word is stripped from the text and the function recursively calls itself
until only one word is available, after which an ending sequence of elements is added.-->
<xsl:template name="recurse_ragged">
	<xsl:param name="text"/> <!-- The text of the paragraph -->
	<xsl:param name="character_width"/>
	<xsl:param name="nominal_glue_width"/>
	
	<!-- Determine whether there is only one word left. -->
	<xsl:choose>
        <xsl:when test="contains($text, ' ')">
		    <!-- There are multiple words left to be added. For ragged alignment this means adding adding a box with the word,
			adding glue with width 0 and stretchability equal to 1.5 times the nominal glue width, adding a penalty with cost zero,
			adding glue with width equal to the nominal glue width and stretchability -1.5 times the ominal glue width (which cancels
			out the stretchability of the preceding glue). -->
    	    <xsl:call-template name="add_box">
	            <xsl:with-param name="word" select="substring-before($text, ' ')"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
	        </xsl:call-template>
			<xsl:call-template name="add_positive_glue">
				<xsl:with-param name="nominal_width" select="$nominal_glue_width"/>
			</xsl:call-template>
			<xsl:call-template name="add_optional_penalty"/>
			<xsl:call-template name="add_negative_glue">			
				<xsl:with-param name="nominal_width" select="$character_width"/>
			</xsl:call-template>
			
			<!-- Recursion -->
    	    <xsl:call-template name="recurse_ragged">
	            <xsl:with-param name="text" select="substring-after($text, ' ')"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
		        <xsl:with-param name="nominal_glue_width" select="$nominal_glue_width"/>
	        </xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
		    <!-- Only one word is left in the text. Add a box with the word, prohibit a break by adding a prohibited penalty,
			add glue with infinite stretchability and enforce a breakpoint by adding a required penalty. -->
    	    <xsl:call-template name="add_box">
	            <xsl:with-param name="word" select="$text"/>
		        <xsl:with-param name="character_width" select="$character_width"/>
	        </xsl:call-template>
			<xsl:call-template name="add_prohibited_penalty" />
			<xsl:call-template name="add_weak_glue" />
			<xsl:call-template name="add_required_penalty" />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- ############################################### All templates below are output related ############################################### --> 

<!-- Add a box containg a given word -->
<xsl:template name="add_box">
	<xsl:param name="word"/>
	<xsl:param name="character_width"/>
    <box>
        <xsl:attribute name="width">
		    <xsl:value-of select="string-length($word) * $character_width"/>
		</xsl:attribute>
        <xsl:value-of select="$word"/>
    </box>
</xsl:template>

<!-- Add glue with the given nominal width and stretchability equal to 1.5 times the nominal width. -->
<xsl:template name="add_standard_glue">
	<xsl:param name="nominal_width"/>
    <glue>
        <xsl:attribute name="width">
		    <xsl:value-of select="$nominal_width"/>
		</xsl:attribute>
        <xsl:attribute name="stretchability">
			<xsl:value-of select="1.5*$nominal_width"/>
		</xsl:attribute>
        <xsl:attribute name="shrinkability">0</xsl:attribute>
    </glue>
</xsl:template>

<!-- Add glue with width 0 and stretchability equal to 1.5 times the nominal width. -->
<xsl:template name="add_positive_glue">
	<xsl:param name="nominal_width"/>
    <glue>
        <xsl:attribute name="width">0</xsl:attribute>
        <xsl:attribute name="stretchability">
			<xsl:value-of select="1.5*$nominal_width"/>
		</xsl:attribute>
        <xsl:attribute name="shrinkability">0</xsl:attribute>
    </glue>
</xsl:template>

<!-- Add glue with the given nominal width and stretchability equal to -1.5 times the nominal width. -->
<xsl:template name="add_negative_glue">
	<xsl:param name="nominal_width"/>
    <glue>
        <xsl:attribute name="width">
		    <xsl:value-of select="$nominal_width"/>
		</xsl:attribute>
        <xsl:attribute name="stretchability">
			<xsl:value-of select="-1.5*$nominal_width" />
		</xsl:attribute>
        <xsl:attribute name="shrinkability">0</xsl:attribute>
    </glue>
</xsl:template>

<!-- Add glue with the given nominal width and stretchability equal to -3 times the nominal width. -->
<xsl:template name="add_double_negative_glue">
	<xsl:param name="nominal_width"/>
    <glue>
        <xsl:attribute name="width">
		    <xsl:value-of select="$nominal_width"/>
		</xsl:attribute>
        <xsl:attribute name="stretchability">
			<xsl:value-of select="-3*$nominal_width" />
		</xsl:attribute>
        <xsl:attribute name="shrinkability">0</xsl:attribute>
    </glue>
</xsl:template>

<!-- Add infinitely stretchable glue. -->
<xsl:template name="add_weak_glue">
    <glue>
        <xsl:attribute name="width">0</xsl:attribute>
        <xsl:attribute name="stretchability">INF</xsl:attribute>
        <xsl:attribute name="shrinkability">0</xsl:attribute>
    </glue>
</xsl:template>

<!-- Add a prohibited penalty. -->
<xsl:template name="add_prohibited_penalty">
    <penalty>
        <xsl:attribute name="penalty">INF</xsl:attribute>
        <xsl:attribute name="break">prohibited</xsl:attribute>
    </penalty>
</xsl:template>

<!-- Add a required penalty. -->
<xsl:template name="add_required_penalty">
    <penalty>
        <xsl:attribute name="penalty">-INF</xsl:attribute>
        <xsl:attribute name="break">required</xsl:attribute>
    </penalty>
</xsl:template>

<!-- Add a penalty with cost 0. -->
<xsl:template name="add_optional_penalty">
    <penalty>
        <xsl:attribute name="penalty">0</xsl:attribute>
        <xsl:attribute name="break">optional</xsl:attribute>
    </penalty>
</xsl:template>
</xsl:transform>