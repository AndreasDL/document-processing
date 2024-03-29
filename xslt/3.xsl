<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- code approve by an owl
"|||||,,,..   ..,,,|||||"
 '||(    |||,|||    )||'
  "||,,,,. "|" .,,,,||"
   .d8888b.   .d8888b.
  o8'  o '8o o8'o   `8o
  o8.    .8o o8.    .8o
   `Y8888P'   `Y8888P'
  ,||''|| \   / ||''||,
 ,||   ||, \ / .||   ||,
 ||     ||  `  ||     ||
,||     '||   ||'     ||,
||      '||   ||'      ||
||       |;   ;|       ||
||      ,|     |,      ||
||,    ,||     ||,    ,||
 ||,  ,|||     |||,  ,||
 '||,,||||,...,||||,,||
   `|||..."|||"...|||'
 %%%%%WWWW%%%%%%WWWW%%%%%
 `````""3$F""""#$F"""""""
        @$.... '$B
       d$$$$$$$$$$:
-->

<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<!-- init template -->
<xsl:template match="paragraph">
    <paragraph>
    <xsl:apply-templates select="@*"/>

    <xsl:variable name="target_node" select= "./branches/branch[last()]/@end"/>

    <!--xsl:call-template name="debug">
        <xsl:with-param name="shortest_paths">_1;2;3;4;undef_</xsl:with-param>
    </xsl:call-template-->

    <!-- get list with shortest path to each node in tree -->
    <xsl:variable name="shortest_paths">
        <xsl:call-template name="find_shortest_paths">
            <xsl:with-param name="list_of_paths">_0;0;0;0;undef_</xsl:with-param>
            <xsl:with-param name="index_count" select="count(./branches/*)"/>
            <xsl:with-param name="index" select="1"/>
        </xsl:call-template>
    </xsl:variable>
   
    <!--xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="$shortest_paths"/>
    <xsl:text>&#xa;</xsl:text-->

    <xsl:variable name="path">
        <xsl:call-template name="extract_path">
            <xsl:with-param name="shortest_paths" select="$shortest_paths"/>
            <xsl:with-param name="curr_index" select="$target_node"/>
            <xsl:with-param name="path"><xsl:value-of select="$target_node"/></xsl:with-param>
        </xsl:call-template>
    </xsl:variable>

    <!--xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="$path"/>
    <xsl:text>&#xa;</xsl:text-->

    <!-- add ; to end of path for easy string splitting -->
    <xsl:call-template name="format_output">
        <xsl:with-param name="path" select="concat(substring-after($path, ';'), ';')"/> 
        <xsl:with-param name="path_index" select="substring-before($path, ';')"/>
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
    </xsl:call-template>

    </paragraph>
</xsl:template>

<xsl:template name="format_output">
    <xsl:param name="path"/> <!-- list firstnode;node;node;node;targetnode; !!note ; at the end! important much--> 
    <xsl:param name="path_index"/>
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->

    <xsl:variable name="stop_index" select="substring-before($path, ';')"/>
    
    <xsl:variable name="start_index">
        <xsl:call-template name="get_start">
            <xsl:with-param name="to" select="$stop_index"/>
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
        </xsl:call-template>
    </xsl:variable>

    <!--xsl:value-of select="concat('line from ', $start_index, ' to ' , $stop_index)"/-->
    <xsl:if test="string-length($stop_index) > 0">
        <line>
            <xsl:attribute name="ratio">
                <xsl:call-template name="get_ratio">
                    <xsl:with-param name="to" select="$stop_index"/>
                    <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
                </xsl:call-template>
                <!--xsl:value-of select="./branches/branch[@start=$start_index and @stop=$stop_index]/@ratio"/-->
            </xsl:attribute>

            <xsl:for-each select="./content/*[position() >= $start_index and $stop_index >= position()]">
                <xsl:copy>
                    <xsl:apply-templates select="node()|@*"/>
                </xsl:copy>
            </xsl:for-each>
        </line>

        <!-- recursion -->
        <xsl:call-template name="format_output">
            <xsl:with-param name="path" select="substring-after($path, ';')"/>
            <xsl:with-param name="path_index" select="$stop_index + 1"/>
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<!-- get shortest path from the list of shortest paths -->
<xsl:template name="extract_path">
    <xsl:param name="shortest_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->
    <xsl:param name="curr_index"/>
    <xsl:param name="path"/>
    
    <!--xsl:value-of select="concat('target', $curr_index)"/>
    <xsl:text>&#xa;</xsl:text-->

    <xsl:variable name="previous">
        <xsl:call-template name="get_previous">
            <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
            <xsl:with-param name="to" select="$curr_index"/>
        </xsl:call-template>
    </xsl:variable>

    <!--xsl:value-of select="concat('previous', $previous)"/>
    <xsl:text>&#xa;</xsl:text-->

    <xsl:choose>
        <xsl:when test="$previous != 'undef'">
            <!--output -->
            <xsl:variable name="new_path" select="concat($previous, ';', $path)"/>

            <!-- recursion -->
            <xsl:call-template name="extract_path">
                <xsl:with-param name="shortest_paths" select="$shortest_paths"/>
                <xsl:with-param name="curr_index" select="$previous"/>
                <xsl:with-param name="path" select="$new_path"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$path"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- returns list of shortest paths to each node -->
<xsl:template name="find_shortest_paths">
    <xsl:param name="index_count"/> <!-- how many branches are there? -->
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->
    <xsl:param name="index"/> <!-- index of the node that we are looking at -->

    <!-- init some vars readability++ -->
    <xsl:variable name="curr_node" select="./branches/*[position() = $index]"/> <!-- current iteration is above this node -->
    <xsl:variable name="curr_index" select="$curr_node/@previous"/> <!-- where are we ? -->
    <xsl:variable name="curr_to_index" select="$curr_node/@end"/> <!-- path goes to ? -->
    
    <!-- is also saved in the list -->
    <xsl:variable name="curr_ratio" select="$curr_node/@ratio"/>
    <xsl:variable name="curr_start" select="$curr_node/@start"/>

    <!-- cost to current node -->
    <xsl:variable name="cost_to_current">
        <xsl:call-template name="get_existing_cost">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$curr_index"/>
        </xsl:call-template>
    </xsl:variable>

    <!--xsl:value-of select="concat('path to ' , $curr_index , ' = ' , $cost_to_current)"/>
    <xsl:text>&#xa;</xsl:text-->

    <xsl:variable name="new_cost" select="$cost_to_current + $curr_node/@cost"/>            
    
    <!--xsl:value-of select="concat('path to ' , $curr_to_index , ' = ' , $new_cost)"/>
    <xsl:text>&#xa;</xsl:text-->

    <!-- cost via existing path, if no path is found then the cost is set to INF -->
    <xsl:variable name="existing_cost">
        <xsl:call-template name="get_existing_cost">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$curr_to_index"/>
        </xsl:call-template>
    </xsl:variable>

    <!-- save lowest cost -->
    <xsl:variable name="new_line" select="concat('_', $curr_to_index , ';', $new_cost , ';' , $curr_ratio, ';' , $curr_start , ';' , $curr_index , '_' )"/> 

    <!-- adjust the list when needed -->
    <xsl:variable name="new_list_of_paths">
        <xsl:choose>
            <!-- existing cost == INF & new path is useable => add to list -->
            <xsl:when test="$existing_cost = 'INF' and $cost_to_current != 'INF'">
                <xsl:value-of select="concat($list_of_paths , $new_line)"/>
            </xsl:when>

            <!-- new cost < existing cose => replace current line with new line -->
            <xsl:when test="$existing_cost > $new_cost and $cost_to_current != 'INF'">
                
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

    <!--xsl:text>&#xa;</xsl:text>
    <xsl:value-of select="$new_list_of_paths"/>
    <xsl:text>&#xa;</xsl:text-->

    <!-- recursion -->
    <xsl:choose>
        <!-- not found yet, 'zoek ma wa verder' -->
        <xsl:when test="$index != $index_count">
            <xsl:call-template name="find_shortest_paths">
                <xsl:with-param name="index_count" select="$index_count"/>
                <xsl:with-param name="index" select="$index + 1"/>
                <xsl:with-param name="list_of_paths" select="$new_list_of_paths"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <!-- path found return the list -->
            <xsl:value-of select="$new_list_of_paths"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- get the entry from the list (used to replace) -->
<xsl:template name="get_existing_line">
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->
    <xsl:param name="to"/>

    <xsl:variable name="query" select="concat('_' , $to , ';')"/>
    <xsl:choose>
        <xsl:when test="contains($list_of_paths , $query)">
            <xsl:value-of select="concat( $query , substring-before(substring-after($list_of_paths , $query), '_') , '_')"/>
        </xsl:when>
        <xsl:otherwise>UNDEF</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- check if we already have a path to the curr_to_index -->
<xsl:template name="get_existing_cost">
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->
    <xsl:param name="to"/>

    <xsl:variable name="line">
        <xsl:call-template name="get_existing_line">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$to"/>
        </xsl:call-template>
    </xsl:variable>
    
    <xsl:variable name="query" select="concat('_' , $to , ';')"/>

    <xsl:choose>
        <xsl:when test="$line != 'UNDEF'"> <!-- found -->
            <!-- list => _to;cost;ratio;start;prev_ => cost -->
            <xsl:value-of select="substring-before( substring-after($line, $query) , ';' )"/>
        </xsl:when>
        <!-- path undefined => infinte cost -->
        <xsl:otherwise>INF</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- get index of previous node -->
<xsl:template name="get_previous">
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->
    <xsl:param name="to"/>

    <xsl:variable name="line">
        <xsl:call-template name="get_existing_line">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$to"/>
        </xsl:call-template>
    </xsl:variable>
    
    <xsl:variable name="query" select="concat('_' , $to , ';')"/>

    <xsl:choose>
        <xsl:when test="$line != 'UNDEF'"> <!-- found -->
            <!-- list => _to;cost;ratio;prev_ => prev -->
            <xsl:value-of select="substring-before( substring-after( substring-after( substring-after( substring-after($line, $query), ';' ), ';' ), ';'), '_')"/>
        </xsl:when>
        <!-- path undefined => infinte cost -->
        <xsl:otherwise>UNDEF</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- get index of previous node -->
<xsl:template name="get_ratio">
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->
    <xsl:param name="to"/>

    <xsl:variable name="line">
        <xsl:call-template name="get_existing_line">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$to"/>
        </xsl:call-template>
    </xsl:variable>
    
    <xsl:variable name="query" select="concat('_' , $to , ';')"/>

    <xsl:choose>
        <xsl:when test="$line != 'UNDEF'"> <!-- found -->
            <!-- list => _to;cost;ratio;start;prev_ => ratio -->
            <xsl:value-of select="substring-before( substring-after( substring-after($line, $query), ';' ), ';' )"/>
        </xsl:when>
        <!-- path undefined => infinte cost -->
        <xsl:otherwise>UNDEF</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="get_start">
    <xsl:param name="list_of_paths"/> <!-- list => _to;cost;ratio;start;prev_ -->
    <xsl:param name="to"/>

    <xsl:variable name="line">
        <xsl:call-template name="get_existing_line">
            <xsl:with-param name="list_of_paths" select="$list_of_paths"/>
            <xsl:with-param name="to" select="$to"/>
        </xsl:call-template>
    </xsl:variable>
    
    <xsl:variable name="query" select="concat('_' , $to , ';')"/>

    <xsl:choose>
        <xsl:when test="$line != 'UNDEF'"> <!-- found -->
            <!-- list => _to;cost;ratio;start;prev_ => ratio -->
            <xsl:value-of select="substring-before( substring-after( substring-after( substring-after($line, $query), ';' ), ';' ), ';' )"/>
        </xsl:when>
        <!-- path undefined => infinte cost -->
        <xsl:otherwise>UNDEF</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- check functions -->
<xsl:template name="debug">
    <xsl:param name="shortest_paths"/>

    <xsl:call-template name="get_existing_cost">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="1"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="get_existing_cost">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="2"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>

    <xsl:call-template name="get_existing_line">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="1"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="get_existing_line">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="2"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>

    <xsl:call-template name="get_previous">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="1"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="get_previous">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="2"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>

    <xsl:call-template name="get_ratio">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="1"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="get_ratio">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="2"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>

    <xsl:call-template name="get_start">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="1"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="get_start">
        <xsl:with-param name="list_of_paths" select="$shortest_paths"/>
        <xsl:with-param name="to" select="2"/>
    </xsl:call-template>
    <xsl:text>&#xa;</xsl:text>


</xsl:template>
</xsl:stylesheet>