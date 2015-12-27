<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

<!-- Copy machine: copies every element that doesn't match another template -->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*[not(name(.) = 'index')]|node()"/>
    </xsl:copy>
</xsl:template>
<!-- Transform the paragraphs -->
<xsl:template match="paragraph">
    <xsl:copy>
        <!-- Copy the paragraph attributes -->
        <xsl:apply-templates select="@*"/>
        
        <xsl:variable name="nrBranches" select="count(./branches/*)"/>
        <xsl:if test="$nrBranches &gt; 0">
            <!-- Find for each break position the branch that leads to the next break position
            on the path with minimal cost to the final paragraph break. The output is structured as:
            '_breakPositionId1;costSinceLastInfOnPathToStop1;nrInfsOnPathToStop1;branchId1_breakPositionId2...;branchIdN_'-->
            <xsl:variable name="sinkTree">
                <xsl:call-template name="find_shortest_path_branch">
                    <xsl:with-param name="branches" select="./branches"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- Now use this sink tree to write the paragraph as a sequence of lines -->
            <xsl:call-template name="write_lines">
                <xsl:with-param name="sinkTree" select="$sinkTree"/>
                <xsl:with-param name="paragraph" select="."/>
            </xsl:call-template>
        </xsl:if>
    </xsl:copy>
</xsl:template>

<!-- This template writes a given paragraph as a sequence of lines. To do so, it uses a sink tree, which is structured as:
'_breakPositionId1;costSinceLastInfOnPathToStop1;nrInfsOnPathToStop1;branchId1_breakPositionId2...;branchIdN_'. Using this tree,
starting from position 0, the taken branch is located and the elements between the start and end of this branch are written as
a line. After this, the function recursively calls itself with the position of last line break as current. The recursion terminates
when there is no next branch on the path to the last break (this is only the case for the last break). -->
<xsl:template name="write_lines">
    <xsl:param name="sinkTree"/>
    <xsl:param name="paragraph"/>
    <xsl:param name="current" select="0"/>
    
    <!-- Get the next branch on the path to the final break, starting from current. -->
    <xsl:variable name="nextInfo" select="substring-before(substring-after($sinkTree, concat('_', $current, ';')), '_')"/>
    <xsl:variable name="branchId" select="number(substring-after(substring-after($nextInfo, ';'), ';'))"/>
    <xsl:variable name="branch" select="$paragraph/branches/branch[$branchId]"/>
    
    <!-- Check whether there is a next branch on the path to the final break. -->
    <xsl:if test="$branchId">
        <!-- There is a next branch! Create a line with all elements between the start and end of this branch. -->
        <line>
            <xsl:attribute name="ratio">
                <xsl:value-of select="$branch/@ratio"/>
            </xsl:attribute>
            <xsl:for-each select="$paragraph/content/*[position() &gt;= $branch/@start and position() &lt;= $branch/@end]">
                <xsl:if test="not(name(.) = 'penalty')">
                    <xsl:apply-templates select="."/>
                </xsl:if>
            </xsl:for-each>
        </line>
        
        <!-- Recursion: search for a branch starting from the end of the current branch -->
        <xsl:call-template name="write_lines">
            <xsl:with-param name="current" select="$branch/@end"/>
            <xsl:with-param name="sinkTree" select="$sinkTree"/>
            <xsl:with-param name="paragraph" select="$paragraph"/>
        </xsl:call-template>        
    </xsl:if>
</xsl:template>

<!-- Determine for each break the branch that leads to the next break on the least cost path to the final break. The output is
structured as: '_breakPositionId1;costSinceLastInfOnPathToStop1;nrInfsOnPathToStop1;branchId1_breakPositionId2...;branchIdN_'.
The path is recursively determined: when startBranchIndex and stopBranchIndex differ, the template calls itself to determine the
shortest paths from the last half of the range of branches and than (using that result), the template calls itself to determine
the shortest path from the first half of the range of branches. This has the effect of executing the case where startBranchIndex
and stopBranchIndex are equal iterating backwards over all the branches (with a recursion tree with a depth proportional to the
logarithm of the number of branches). When startBranchIndex and stopBranchIndex are equal, the cost of using the current branch to
reach the final break is calculated (the sum of the cost of the branch and the cost of going to the destination through the branch end).
When there is no cost from the branch previous to the final break, or this cost improves upon current cost, an updated version of
distances is returned. Otherwise distance is returned unchanged. -->
<xsl:template name="find_shortest_path_branch">
    <xsl:param name="branches"/>
    <xsl:param name="startBranchIndex" select="1"/>
    <xsl:param name="stopBranchIndex" select="count($branches/*)"/>
    <xsl:param name="distances" select="concat('_', ./branches/branch[last()]/@end, ';0;0;_')"/>
    
    <!-- Determine whether the range of branches to find the shortest path for consists of only one branch -->
    <xsl:choose>
        <xsl:when test="$startBranchIndex = $stopBranchIndex">
            <!-- There is only one branch. Determine the cost of going to the final break through this branch -->
            <xsl:variable name="currentBranch" select="$branches/branch[$startBranchIndex]"/>

            <xsl:variable name="distancesCurNext" select="substring-before(substring-after($distances, concat('_', $currentBranch/@end, ';')), '_')"/>
            <xsl:variable name="curNextCostNorm" select="substring-before($distancesCurNext, ';')"/>
            <xsl:variable name="curNextCostInf" select="substring-before(substring-after($distancesCurNext, ';'), ';')"/>
    
            <xsl:variable name="curCostNorm">
                <xsl:choose>
                    <xsl:when test="not($currentBranch/@cost = '-INF')">
                        <xsl:value-of select="$curNextCostNorm + $currentBranch/@cost"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="0"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- curCostInf is the number of required breaks on the path from this break to the final break.
            Paths with more required breaks are always better. -->
            <xsl:variable name="curCostInf">
                <xsl:choose>
                    <xsl:when test="not($currentBranch/@cost = '-INF')">
                        <xsl:value-of select="$curNextCostInf"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$curNextCostInf+1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="previousInfo" select="substring-before(substring-after($distances, concat('_', $currentBranch/@previous, ';')), '_')"/>
            <xsl:variable name="prevCostNorm" select="substring-before($previousInfo, ';')"/>
            <xsl:variable name="prevCostInf" select="substring-before(substring-after($previousInfo, ';'), ';')"/>
            <!-- Compare the cost of going through the current pranch with the cost of using any previously added branch -->
            <xsl:choose>
                <xsl:when test="not($previousInfo)">
                    <!-- There is no previously added branch. Add the cost of using this branch -->
                    <xsl:value-of select="concat('_', $currentBranch/@previous, ';', $curCostNorm, ';', $curCostInf, ';', $startBranchIndex, $distances)"/>
                </xsl:when>
                <xsl:when test="($curCostInf &gt; $prevCostInf) or ($curCostInf = $prevCostInf and $curCostNorm &lt;= $prevCostNorm)">
                    <!-- There is a previous branch, but the cost of going through the current branch improves upon using the previous branch 
                    (there are more required breaks on this path, or there are an equal amount of required breaks and cost of using this branch to
                    reach the next required break is lower). -->
                    <xsl:value-of select="concat('_', $currentBranch/@previous, ';', $curCostNorm, ';', $curCostInf, ';', $startBranchIndex , '_', substring-after(substring-after($distances, concat('_', $currentBranch/@previous, ';')), '_'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- There already was a branch, and it was a better choise than this one -->
                    <xsl:value-of select="$distances"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- Multiple to find the shortest path for. Search shortest paths using the last half of the branches of range, then use the result of
            this to find shortest paths using the branches of the first half of the range. Return this final result. -->
            <xsl:variable name="halfBranchIndex" select="floor($startBranchIndex + ($stopBranchIndex -$startBranchIndex)*0.5)"/>
            <xsl:variable name="last">
                <xsl:call-template name="find_shortest_path_branch">
                    <xsl:with-param name="startBranchIndex" select="$halfBranchIndex+1"/>
                    <xsl:with-param name="stopBranchIndex" select="$stopBranchIndex"/>
                    <xsl:with-param name="branches" select="$branches"/>
                    <xsl:with-param name="distances" select="$distances"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="first">
                <xsl:call-template name="find_shortest_path_branch">
                    <xsl:with-param name="startBranchIndex" select="$startBranchIndex"/>
                    <xsl:with-param name="stopBranchIndex" select="$halfBranchIndex"/>
                    <xsl:with-param name="branches" select="$branches"/>
                    <xsl:with-param name="distances" select="$last"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="$first"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>