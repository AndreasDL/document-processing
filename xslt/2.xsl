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

<!-- find all branches, given a start and previous index -->
<xsl:template name="find_end">
    <!-- readonly -->
    <xsl:param name="curr_para"/>
    <xsl:param name="prev_index"/>
    <xsl:param name="start_index"/>
    <xsl:param name="l_max"/>
    <!-- will change during recursion -->
    <xsl:param name="stop_index"/> <!--init at start -->
    <xsl:param name="l_prev"/> <!-- init at 0 -->
    <xsl:param name="y_prev"/> <!-- init at 0 -->
    <xsl:param name="z_prev"/> <!-- init at 0 -->

    <!-- readability++ -->
    <xsl:variable name="curr_element" select="$curr_para[position() = $stop_index]"/>
    <xsl:variable name="next_element" select="$curr_para[position() = $stop_index+1]"/>

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
            <xsl:when test="$curr_element/@shrinkability = ''">
                <xsl:value-of select="$y_prev"/>
            </xsl:when>

            <xsl:otherwise>
                <xsl:value-of select="$y_prev + $curr_element/@shrinkability"/>
            </xsl:otherwise>
        </xsl:choose> 
    </xsl:variable>

    <!-- get ratio -->
    <xsl:variable name="ratio">
        <xsl:call-template name="get_ratio">
            <xsl:with-param name="l_max" select="$l_max"/>
            <xsl:with-param name="l_curr" select="$l_curr"/>
            <xsl:with-param name="y_curr" select="$y_curr"/>
            <xsl:with-param name="z_curr" select="$z_curr"/>
        </xsl:call-template>
    </xsl:variable>

    <!-- can we split ? -->
    <!-- we can only split on a penalty if its penalty is < INF and the break is required or optional. -->
    <!-- we can only split on a box if the next element is not a penalty -->
    <!-- we can only split if the ratio is > -1 and ratio != NaN-->
    <xsl:if test="
    (
        (
                name($curr_element) = 'penalty' 
            and 
                not( 
                        $curr_element/@penalty = 'INF' 
                    or
                        $curr_element/@break='prohibited'
                )
        ) or (
                name($curr_element) = 'box'
            and
                name($next_element) != 'penalty'
        )
    ) and (
            $ratio > -1 
        and 
            number($ratio) = number($ratio)
    )">

        <!-- get cost -->
        <xsl:variable name="cost">
            <xsl:call-template name="get_cost">
                <xsl:with-param name="ratio" select="$ratio"/>
                <xsl:with-param name="curr_element" select="$curr_element"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- write branch -->
        <xsl:call-template name="writeBranch">
            <xsl:with-param name="ratio" select="$ratio"/>
            <xsl:with-param name="cost" select="$cost"/>
            <xsl:with-param name="prev_index" select="$prev_index"/>
            <xsl:with-param name="start_index" select="$start_index"/>
            <xsl:with-param name="stop_index" select="$stop_index"/>
        </xsl:call-template>

        <!-- recursion -->
        <!-- continue recursion if we are not at end of paragraph -->
        <!-- and if current width - current shrink < line width -->
        <xsl:if test="
            count($curr_para/*) > $stop_index 
        and
            $l_max > ($l_curr - $z_curr)
        ">
            <xsl:call-template name="find_end">
                <!-- readonly -->
                <xsl:with-param name="curr_para" select="$curr_para"/>
                <xsl:with-param name="prev_index" select="$prev_index"/>
                <xsl:with-param name="start_index" select="$start_index"/>
                <xsl:with-param name="l_max" select="$l_max"/>
                <!-- update these -->
                <xsl:with-param name="stop_index" select="$stop_index + 1"/> 
                <xsl:with-param name="l_prev" select="$l_curr"/>
                <xsl:with-param name="y_prev" select="$y_curr"/>
                <xsl:with-param name="z_prev" select="$z_curr"/>
            </xsl:call-template>
        </xsl:if>
</xsl:template>

<!-- calculate the ratio -->
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
                        <xsl:value-of select="NaN"/>
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
                        <xsl:value-of select="NaN"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:value-of select="$ratio"/>
</xsl:template>

<!-- calculate the cost -->
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

<!-- write branch to output -->
<xsl:template name="writeBranch">
    <xsl:param name="ratio"/>
    <xsl:param name="cost"/>
    <xsl:param name="prev_index"/>
    <xsl:param name="start_index"/>
    <xsl:param name="stop_index"/>

    <branch>
        <xsl:attribute name="cost">
            <xsl:value-of select="$cost"/>
        </xsl:attribute>

        <xsl:attribute name="ratio">
            <xsl:value-of select="$ratio"/>
        </xsl:attribute>
        
        <xsl:attribute name="start">
            <xsl:value-of select="$start_index"/>
        </xsl:attribute>

        <xsl:attribute name="end">
            <xsl:value-of select="$stop_index"/>
        </xsl:attribute>

        <xsl:attribute name="previous">
            <xsl:value-of select="$prev_index"/>
        </xsl:attribute>
    </branch>
</xsl:template>

</xsl:stylesheet>