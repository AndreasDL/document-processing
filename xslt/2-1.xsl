<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- preprocessing step for step 2. This step adds breakpoint information for each element that simplifies the calculate branches part (as was suggested by the teaching staff to a collegue of me). This code is written in xslt, and thus not clean therefore a code monkey is provided below to stop you from going to the dark side

                     .-"""-.
                   _/-=-.   \
                  (_|a a/   |_
                   / "  \   ,_)
              _    \`=' /__/
             / \_  .;''  `-.
             \___)//      ,  \
              \ \/;        \  \
               \_.|         | |
                .-\ '     _/_/
              .'  _;.    (_  \
             /  .'   `\   \\_/
            |_ /       |  |\\
           /  _)       /  / ||
          /  /       _/  /  //
          \_/       ( `-/  ||
                    /  /   \\ .-.
                    \_/     \'-'/
                             `"`
-->

<xsl:template match="paragraph/node()" >
    <!-- note that this copy already sets tags for the glue and the boxes -->

    <xsl:copy>
        <!-- add index-->
        <xsl:attribute name="index">
            <xsl:number/>
        </xsl:attribute>

        <xsl:choose>
            <xsl:when test="name() = 'glue'">
                <!-- linebreak after glue will never (the glue should be removed when a line break occurs) => set break to prohibited -->
                <xsl:attribute name="break">prohibited</xsl:attribute>
            </xsl:when>

            <xsl:when test="name() = 'box'">
                <!-- next element == penalty => prohibited break otherwise break = optional -->
                <xsl:variable name="next-element" select="following-sibling::node()[1]" />
                <xsl:variable name="next-next-element" select="following-sibling::node()[2]" />

                <xsl:choose>

                    <!-- don't break on the first item, since justified alignment is won't work with one word and don't break before a penalty-->
                    <xsl:when test="position() = 1 or name($next-element) = 'penalty'">
                        <xsl:attribute name="break">prohibited</xsl:attribute>
                    </xsl:when>
                    
                    <!-- glue before penalty => prohibited break -->
                    <xsl:when test="name($next-element) = 'glue' and name($next-next-element) = 'penalty'">
                        <xsl:attribute name="break">prohibited</xsl:attribute>
                    </xsl:when>

                    <!-- else breaks are allowed -->
                    <xsl:otherwise>
                        <xsl:attribute name="break">optional</xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>

        <!-- copy original stuffz -->
        <xsl:apply-templates select="@*|node()"/>

    </xsl:copy>
    
</xsl:template>

<xsl:template match="document/paragraph">
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <!-- fix child elements -->
        <xsl:apply-templates select="node()"/>
    </xsl:copy>        
</xsl:template> 

<xsl:template match="document|@*">
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates select="paragraph"/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>