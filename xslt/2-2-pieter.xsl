<?xml version="1.0" encoding="UTF-8"?>
<!-- The pelican sepates the good fish from the bad ones.
                            `.- -...__
                           /```.__    ``.
                           |```/  `'- .._`.
                           |``|        (o).)
                           \`` \    _,-'   `.
                            \```\  ( ( ` .   `.
                             `.```. `.` . `    `.
                               `.``\  `.__   `.  `.
                              ___\``), )\ `-.  `.  `.
                    __    _,-'   \,'  /  \   `-.  `. `.
                 ,-' '`,-'  '  ''| '   ' |      `-. `. `.
              ,-''_,-' '  ' '  ' |   '  '|         `-. `.`.
           ,-'_,-'   '   '  ''   | '  '  |            `-.`.`.
        ,-',-'  ''  ,'   |   |   |'   ' /                `-..`.
      ,' ,'  ' '     |  ,' | ,' /    ' '|                   `-.)
     // /  '   |    ,'    ,'   /   '  '/
     | || ,'  ,' |    ,' |   ,'   '   '|
     ||||   |   ,' ,'   ,' ,' ' '     /
     |  | |,'  '     |'  ,'  '   '  '/
     | ||,'   ,' |  ,' ,' '    \   '/
     ||||  |  , ,'  ,-'  /  ' '| ','
     | /  ,' '   ,-' '   |'    |,'
     | | ' ,' ,-' '  ' ' |    '|
     |||,' ,-'  '  '   '_|'  '/
     |,|,-' /'___,.. -''  \ ' |
     / // ,'-' |' |        \  |
    ///,-'      \ |         \'|
   ' -'          \'\        | |
               __ ) \___  __| |_
 ____,...- - ''   ||`-  <_.- ._ -`- . __
                  ''            `-`     `'''''''- - -......_____
-->

<!-- This transform removes all branches that are not reachable from the position 0 of the break point tree.
This step is not strictly necessary (removing it will not affect the solution of the algorithm and is even beneficial
for the total running time), but the assignment asked for a line break graph and (to my option) a line break graph should
not contain branches that are unreachable from position 0. -->

<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="UTF-8"/>
<xsl:variable name="doc_line_width" select="/document/@line-width" />

<!-- Copy machine: copies every element that doesn't matches another template -->
<xsl:template match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<!-- Remove any branches that are unreachable from position 0 -->
<xsl:template match="branches">
	<xsl:copy>
		<xsl:variable name="nrBranches" select="count(./*)"/>
		<xsl:if test="count(./*) &gt; 0">
			<!-- Find out which positions are reachable from position 0. This template returns a string:
			'-position_0-position_1-...-position_i-position_{i+1}-..-position_N-' of all positions that are reachable
			from position 0 -->
			<xsl:variable name="reachableBranches">
				<xsl:call-template name="find_reachable_branches">
					<xsl:with-param name="branches" select="."/>
				</xsl:call-template>
			</xsl:variable>
			
			<!-- Now use this set of reachable positions to write only those branches that are reachable -->
			<xsl:for-each select="./*">
				<xsl:if test="contains($reachableBranches, concat('-', ./@previous, '-'))">
					<xsl:apply-templates select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:copy>
</xsl:template>

<!-- This template finds out which branches between startBranchIndex and stopBranchIndex are reachable from
position the positions passed in reachableBranches. reachableBranches is a string '-position_0-position_1-
...-position_i-position_{i+1}-..-position_N-' of positions that are reachable, and the template outputs a similar string,
containing the position that were passed, plus the positions of additional reachable nodes discovered between startIndex
and stopIndex. The reachability analysis is recursively performed: when startBranchIndex and stopBranchIndex differ, the function
calls itself to perform reachablilty analysis on the first half on the index range and then uses that result to perform reachability
analysis on the second half of the index range. This has the effect of iterating forward through all the branches. When startBranchIndex
equals stopBranchIndex the template checks whether the tested branch its previous position is reachable and, if this is the case, adds
its end position (if necessary) to the set of reachable nodes.
Note that this approach has the advantage that the depth of the recursion tree is logarithmic in the nr of reachable branches, which means
that the stack size increases logarithmically when the number of branches increases. -->
<xsl:template name="find_reachable_branches">
	<xsl:param name="branches"/>
	<xsl:param name="reachableBranches" select="'-0-'"/> <!-- When the algorithm starts, node 0 is the only reachable node -->
	<xsl:param name="startBranchIndex" select="1"/>
	<xsl:param name="stopBranchIndex" select="count($branches/*)"/>
		
	<!-- Check whether the range of branches to analyze consists of only one branch -->
	<xsl:choose>
		<xsl:when test="$startBranchIndex = $stopBranchIndex">
			<!-- Only one branch to analyze. Check whether its previous position is reachable. If this is the case and the end is not yet in the reachable set,
			add the end and return the adapted set. Otherwise, return the input set. -->
			<xsl:variable name="currentBranch" select="$branches/branch[$startBranchIndex]"/>
			<xsl:choose>
				<xsl:when test="contains($reachableBranches, concat('-', $currentBranch/@previous, '-')) and not(contains($reachableBranches, concat('-', $currentBranch/@end, '-')))">
					<xsl:value-of select="concat($reachableBranches, $currentBranch/@end, '-')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($reachableBranches)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:otherwise>
			<!-- Multiple branches to analyze. Perform reachability analysis on the first half of the range, use the result of this to perform reachability analysis
			on the second half of the range and return this result of this last analysis. -->
			<xsl:variable name="halfBranchIndex" select="floor($startBranchIndex + ($stopBranchIndex -$startBranchIndex)*0.5)"/>
			<xsl:variable name="first">
				<xsl:call-template name="find_reachable_branches">
					<xsl:with-param name="startBranchIndex" select="$startBranchIndex"/>
					<xsl:with-param name="stopBranchIndex" select="$halfBranchIndex"/>
					<xsl:with-param name="branches" select="$branches"/>
					<xsl:with-param name="reachableBranches" select="$reachableBranches"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="last">
				<xsl:call-template name="find_reachable_branches">
					<xsl:with-param name="startBranchIndex" select="$halfBranchIndex+1"/>
					<xsl:with-param name="stopBranchIndex" select="$stopBranchIndex"/>
					<xsl:with-param name="branches" select="$branches"/>
					<xsl:with-param name="reachableBranches" select="$first"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:value-of select="$last"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
</xsl:transform>