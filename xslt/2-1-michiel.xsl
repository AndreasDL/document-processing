<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <!--
       
    This stylesheet does nothing more than adding breakpoint information to every element.
    This will prove to be helpful when calculating branches in the next stap.
    
    Note that this step does not depend on the alignment of the paragraph anymore.
       
    -->
    
    <!-- Indicate that the output is also an xml file -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"/>
    
    <xsl:template match="document|@*">
        <xsl:copy>
            <!-- write the element attributes (@*) -->
            <xsl:apply-templates select="@*"/>
            
            <!-- perform operations on paragraph elements -->
            <xsl:apply-templates select="paragraph">

            </xsl:apply-templates>
            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="document/paragraph">
        
        <xsl:copy>
            <!-- Copy all atributes and information -->
            <xsl:apply-templates select="@*"/>
            
            <!-- Apply the template to preprocess the nodes
                by adding and index and break attribute -->
            <xsl:apply-templates select="node()"/>
        </xsl:copy>        
    </xsl:template>
    
    <xsl:template match="paragraph/node()">
        
        <xsl:copy>
            
            <!-- Add index attribute -->
            <xsl:attribute name="index">
                <xsl:number/>
            </xsl:attribute>
            
            <xsl:choose>
                
                <!-- Add break attribute to boxes... -->
                <xsl:when test="name() = 'box'">
                    <!-- Box element followed by penalty? break="prohibited"
                    Box that isn't followed by a penalty? break="optional" -->
                    
                    <xsl:choose>
                        
                        <!-- Is following node a penalty? ==> break is prohibited... -->
                        <xsl:when test="name(following-sibling::node()[1]) = 'penalty'">
                            <xsl:attribute name="break">prohibited</xsl:attribute>
                        </xsl:when>
                        
                        <!-- Is the following node a glue and the node after that a penalty? ==> break is prohibited ... -->
                        <xsl:when test="name(following-sibling::node()[1]) = 'glue' and name(following-sibling::node()[2]) = 'penalty'">
                            <xsl:attribute name="break">prohibited</xsl:attribute>
                        </xsl:when>
                        
                        <!-- The first box will also have a prohibited break. This is necessary for the justified
                            alignment (justified alignment is not possible with only 1 word on a line), and does not affect
                            the calculations for all other alignments... -->
                        <xsl:when test="position() = 1">
                            <xsl:attribute name="break">prohibited</xsl:attribute>
                        </xsl:when>
                        
                        <!-- In all other cases the breaks are optional... -->
                        <xsl:otherwise>
                            <xsl:attribute name="break">optional</xsl:attribute>
                        </xsl:otherwise>
                        
                    </xsl:choose>
                    
                </xsl:when>
                
                <!-- Add break attribute to glues... -->
                <xsl:when test="name() = 'glue'">
                    
                    <!-- A linebreak will never appear after a glue, therefore the attribute will always be set to prohibited... -->
                    <xsl:attribute name="break">prohibited</xsl:attribute>
                    
                </xsl:when>
            </xsl:choose>
            
            <!-- Copy existing element attributes -->
            <xsl:apply-templates select="@*|node()"/>
            
        </xsl:copy>
        
    </xsl:template>
    
</xsl:stylesheet>