<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>



<!-- init template -->
<xsl:template match="branches">
    <xsl:variable name="target_index" select="./branch[last()]/@stop"/>
    <xsl:variable name="list_of_paths">_1;0;undef_</xsl:variable><!-- list => _to;cost;prev_ -->


    <xsl:call-template name="get_existing_cost">
        <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
        <xsl:with-param name="to" select="1"/>
    </xsl:call-template>

    <xsl:call-template name="get_existing_line">
        <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
        <xsl:with-param name="to" select="1"/>
    </xsl:call-template>

    <!-- find shortest path -->
    <xsl:variable name="shortest_paths">
        <xsl:call-template name="find_shortest_paths">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="target_index" select="$target_index"/>
            <xsl:with-param name="curr_node" select="./branches/branch[1]"/>
        </xsl:call-template>
    </xsl:variable>

    <xsl:value-of select="$shortest_paths"/>


</xsl:template>

<!-- returns list of shortest paths to each node -->
<xsl:template name="find_shortest_paths">
    <xsl:param name="target_index"/> <!-- index of last element -->
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;prev_ -->
    <xsl:param name="curr_node"/> <!-- current iteration is above this node -->

    <xsl:variable name="curr_index" select="$curr_node/@start"/> <!-- where are we ? -->
    <xsl:variable name="curr_to_index" select="$curr_node/@stop"/> <!-- path goes to ? -->

    <!-- cost to current node, should always be defined -->
    <xsl:variable name="cost_to_current">
        <xsl:call-template name="get_existing_cost">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$curr_index"/>
        </xsl:call-template>
    </xsl:variable>

    <!--xsl:value-of select="concat('path to ' , $curr_index , ' = ' , $cost_to_current)"/-->

    <xsl:variable name="new_cost" select="$cost_to_current + $curr_node/@cost"/>
    
    <!--xsl:value-of select="concat('path to ' , $curr_to_index , ' = ' , $new_cost)"/-->

    <!-- cost via existing path, if no path is found then the cost is set to INF -->
    <xsl:variable name="existing_cost">
        <xsl:call-template name="get_existing_cost">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$curr_to_index"/>
        </xsl:call-template>
    </xsl:variable>

    <!-- save lowest cost -->
    <xsl:variable name="new_line" select="concat('_', $curr_to_index , ';', $new_cost , $curr_node/@previous , '_' )"/>

    <!-- adjust the list when needed -->
    <xsl:variable name="new_list_of_paths">
        <xsl:choose>
            <!-- existing cost == INF => add to list -->
            <xsl:when test="$existing_cost = 'INF'">
                <xsl:value-of select="concat($list_of_paths , $new_line)"/>
            </xsl:when>

            <!-- new cost < existing cose => replace current line with new line -->
            <xsl:when test="$existing_cost > $new_cost">
                <xsl:variable name="old_line">
                    <xsl:call-template name="get_existing_line">
                        <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
                        <xsl:with-param name="to" select="$curr_to_index"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:value-of select="concat(substring-before($list_of_paths, $old_line) , $new_line , substring-after($list_of_paths, $old_line))"/>
            </xsl:when>

            <!-- else: nothing changes -->
            <xsl:otherwise>
                <xsl:value-of select="$list_of_paths"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- recursion -->
    <xsl:choose>
        <!-- not found yet, 'zoek ma wa verder' -->
        <xsl:when test="$curr_to_index != $target_index">
            <xsl:call-template name="find_shortest_paths">
                <xsl:with-param name="target_index" select="$target_index"/>
                <xsl:with-param name="list_of_paths" select="$new_list_of_paths"/>
                <xsl:with-param name="curr_node" select="./following::sibling[1]"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <!-- path found return the list -->
            <xsl:value-of select="$new_list_of_paths"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- check if we already have a path to the curr_to_index -->
<xsl:template name="get_existing_cost">
    <xsl:param name="list_of_paths"/><!-- list => _to;cost;prev_ -->
    <xsl:param name="to"/>

    <xsl:variable name="query" select="concat('_' , $to , ';')"/>
    <xsl:choose>
        <xsl:when test="contains($list_of_paths , $query)">
            <!-- path is defined, return the cost -->
            <xsl:value-of select="substring-before(substring-after($list_of_paths , $query), ';')"/>
        </xsl:when>
        <xsl:otherwise>
            <!-- path undefined => infinte cost -->
            <xsl:value-of select="INF"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- get the entry from the list (used to replace) -->
<xsl:template name="get_existing_line">
    <xsl:param name="list_of_paths"/><!-- list => _to;cost;prev_ -->
    <xsl:param name="to"/>

    <xsl:variable name="query" select="concat('_' , $to , ';')"/>

    <xsl:value-of select="concat( $query , substring-before(substring-after($list_of_paths , $query), '_'))"/>
</xsl:template>

</xsl:stylesheet>