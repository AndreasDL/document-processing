<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>    

<!-- Copy all other elements (document)-->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="paragraph">
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        
        <!-- put content in place -->
        <content>
            <xsl:copy-of select="current()/*"/>
        </content>

        <branches>

            
        </branches>


    </xsl:copy>
</xsl:template>

<xsl:template name="find_start">
    <xsl:param name="curr_para"/>

</xsl:template>

<xsl:template name="find_end">
    <!-- readonly -->
    <xsl:param name="curr_para"/>
    <xsl:param name="previous"/>
    <xsl:param name="start"/>
    <xsl:param name="l_max"/>
    <!-- will change during recursion -->
    <xsl:param name="stop"/> <!--init at start -->
    <xsl:param name="l_prev"/> <!-- init at 0 -->
    <xsl:param name="y_prev"/> <!-- init at 0 -->
    <xsl:param name="z_prev"/> <!-- init at 0 -->

    <!-- readability++ -->
    <xsl:variable name="curr_element"  select="./*[position() = $stop]"/>

    <!-- update l , y, z values -->
    <xsl:variable name="l_curr">
        <xsl:choose>
            <xsl:when test="$curr_element/@width = ''">
                <xsl:value-of select="$l_prev"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$l_prev + $curr_element/@width"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- calculate y_curr -->
    <xsl:variable name="y_curr">
        <xsl:choose>
            
            <!-- infinity is not supported, when -INF or +INF set this value -->
            <xsl:when test="$curr_element/@stretchability = 'INF' or $y_prev = 'INF'">
                <xsl:value-of select="'INF'"/>
            </xsl:when>
            
            <!-- no stretchability for the element => nothing changes -->
            <xsl:when test="$curr_element/@stretchability = ''">
                <xsl:value-of select="$y_prev"/>
            </xsl:when>

            <xsl:otherwise>
                <xsl:value-of select="$y_prev + $curr_element/@stretchability"/>
            </xsl:otherwise>
        </xsl:choose> 
    </xsl:variable>

    <!-- calculate z_curr -->
    <xsl:variable name="z_curr">
        <xsl:choose>
            
            <!-- infinity is not supported, when -INF or +INF set this value -->
            <xsl:when test="$curr_element/@shrinkability = 'INF' or $z_prev = 'INF'">
                <xsl:value-of select="'INF'"/>
            </xsl:when>
            
            <!-- no stretchability for the element => nothing changes -->
            <xsl:when test="$curr_element/@stretchability = ''">
                <xsl:value-of select="$y_prev"/>
            </xsl:when>

            <xsl:otherwise>
                <xsl:value-of select="$y_prev + $curr_element/@stretchability"/>
            </xsl:otherwise>
        </xsl:choose> 
    </xsl:variable>

    <!-- Calculate the ratio -->
    <xsl:variable name="ratio">
        <xsl:call-template name="get_ratio">
            <xsl:with-param name="l_max" select="$l_max"/>
            <xsl:with-param name="l_curr" select="$l_curr"/>
            <xsl:with-param name="y_curr" select="$y_curr"/>
            <xsl:with-param name="z_curr" select="$z_curr"/>
        </xsl:call-template>
    </xsl:variable>

    <!-- can we split ? -->
    <xsl:if test=""/>


</xsl:template>

<xsl:template name="get_ratio">
    <!--slide 23-->
    <xsl:param name="l_max"/>
    <xsl:param name="l_curr"/>
    <xsl:param name="y_curr"/>
    <xsl:param name="z_curr"/>

    <xsl:variable name="ratio">
        <xsl:choose>
            <!-- perfect fit -->
            <xsl:when test="$l_max = $l_curr">
                <xsl:value-of select="0"/>
            </xsl:when>
            
            <!-- stretch ($l_curr < $l_max) -->
            <xsl:when test="$l_max > $l_curr">
                <xsl:choose>
                    <!-- normal case -->
                    <xsl:when test="0 > $y_curr and $y_curr != 'INF'">
                        <xsl:value-of select="($l_max - ($l_curr)) div $y_curr"/>
                    </xsl:when>
                    
                    <!-- undef -->
                    <xsl:otherwise>
                        <xsl:value-of select="0"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- shrink ($l_curr > $l_max) -->
            <xsl:otherwise>
                <xsl:choose>
                    <!-- normal case -->
                    <xsl:when test="0 > $z_curr and $z_curr != 'INF'">
                        <xsl:value-of select="($l_max - ($l_curr)) div $z_curr"/>
                    </xsl:when>
                    
                    <!-- undef -->
                    <xsl:otherwise>
                        <xsl:value-of select="0"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:value-of select="$ratio"/>
</xsl:template>

<xsl:template name="get_cost">
    <xsl:param name="ratio"/>
    <xsl:param name="curr_element"/>

    <!--http://stackoverflow.com/questions/804421/how-can-i-calculate-the-absolute-value-of-a-number-in-xslt-->
    <xsl:variable name="abs_ratio" select="($ratio*($ratio >=0) - $ratio*($ratio &lt; 0))"/>

    <!-- slide 24 -->
    <xsl:variable name="penalty_for_spacing" select="round($abs_ratio * $abs_ratio * $abs_ratio * 100)"/>

    <xsl:variable name="penalty_for_breaking">
        <xsl:choose>
            <xsl:when test="$curr_element/@penalty">
                <xsl:value-of select="$curr_element/@penalty"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- return -->
    <xsl:choose>
        <!-- element is a number -->
        <!-- http://stackoverflow.com/questions/6895870/xslt-1-0-how-to-test-for-numbers -->
        <xsl:when test="number($penalty_for_breaking) = number($penalty_for_breaking)">
            <xsl:value-of select="$penalty_for_breaking + $penalty_for_spacing"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$penalty_for_spacing"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>