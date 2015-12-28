<?xml version="1.0" encoding="UTF-8"?>
<!-- Warning: proceed only if you know how to handle extreme recursion and possibly violent flamingo's.
            .-.
           ((`-)
            \\
             \\
      .="""=._))
     /  .,   .'
    /__(,_.-'
   `    /|
       /_|__
         | `))
         |
        -"==
-->

<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="UTF-8"/>
<xsl:variable name="doc_line_width" select="/document/@line-width" />

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
		<content>
			<!-- Add an index attribute to paragraph element (box, glue, ...) and copy them. Except for the penalties,
			because their attributes are no longer usefull after this step. -->
			<xsl:for-each select="node()">
				<xsl:copy>
				    <xsl:attribute name="index">
		                <xsl:value-of select="count(preceding-sibling::*)+1"/>
		            </xsl:attribute>
					<xsl:if test="not(self::penalty)">
							<xsl:apply-templates select="@*|node()"/>
					</xsl:if>
				</xsl:copy>
			</xsl:for-each>
		</content>
		<branches>
			<!-- Add branches with previous 0 and start 1 -->
            <xsl:call-template name="find_end">
				<xsl:with-param name="previous" select="0"/>
				<xsl:with-param name="start" select="1"/>
				<xsl:with-param name="paragraph" select="."/>
            </xsl:call-template>
			
			<!-- For all possible breakpoints (penalties and boxes which are not followed by a penalty),
			look for the first box after the breakpoint and add all branches with previous equal to the
			break point, and start equal to the subsequent box position. -->
			<xsl:for-each select="./box|./penalty">
				<xsl:variable name="index" select="count(preceding-sibling::*)+1"/>
				<xsl:if test="not(name(.) = 'box') or not(name(../*[$index+1]) = 'penalty')">
					<xsl:call-template name="find_start">
						<xsl:with-param name="previous" select="$index"/>
						<xsl:with-param name="paragraph" select=".."/>
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>
		</branches>
	</xsl:copy>
</xsl:template>

<!-- This template looks for the first box after a position 'previous' in the branches of the given paragraph and then
makes a call that adds all branches with previous equal to the given parameter and start equal to the found position.
The template searches for the start position by recursively calling itself to look at an incremented position,
starting from the position after the previous position. -->
<xsl:template name="find_start">
	<xsl:param name="previous"/>
	<xsl:param name="current" select="$previous + 1"/> <!-- default value: start looking from the position after previous -->
	<xsl:param name="paragraph"/>
	<!-- Check whether there is a box at the given position -->
    <xsl:choose>
		<!-- This position contains a box and thus this is a suitable start. Now add all branches with previous equal to
		the given parameter and start equal to the found position. -->
        <xsl:when test="name($paragraph/*[$current]) = 'box'">
			<xsl:call-template name="find_end">
				<xsl:with-param name="previous" select="$previous"/>
				<xsl:with-param name="start" select="$current"/>
				<xsl:with-param name="paragraph" select="$paragraph"/>
			</xsl:call-template>
        </xsl:when>
		
		<!-- The position does not contains a box. Try again one position further (if possible). -->
        <xsl:when test="$current &lt; count($paragraph/*)">
			<xsl:call-template name="find_start">
				<xsl:with-param name="previous" select="$previous"/>
				<xsl:with-param name="current" select="$current + 1"/>
				<xsl:with-param name="paragraph" select="$paragraph"/>
			</xsl:call-template>
        </xsl:when>
    </xsl:choose>
</xsl:template>

<!-- This template adds all possible branches between a given previous and start position and any ending position,
except for those branches that are trivially useless. A branch with end a is trivially useless if there exist another branch
with end b which has the same previous p and start position, which also  has a lower cost and with no box element in the elements
in [a, b[. This is because each element c that can be reached from p through a can also be reached through b with precisely the
same cost for going from a to c as for going from b to c (since there is no box in [a, b[) and a lower cost for going from p to b
compared to going from p to a.
The arguments are a paragraph containing the elements (boxes, glues,...) and the previous and start position of the branches to be
added. The template operates by recursively calling itself to investigate an incementing ending position current. The sum of the
widths of the elements between start and current is passed via width_sum, and analogue for the stretchabilities and shrinkabilities via
stretch_sum and shrink_sum. The best ending position, ratio and cost since the last encountered box are passed through best_end,
best_ratio and best_cost. -->
<xsl:template name="find_end">
	<xsl:param name="previous"/> <!-- previous position af branches to be added -->
	<xsl:param name="start"/> <!-- start position af branches to be added -->
	<xsl:param name="current" select="$start"/> <!-- end point to investigate in this call (start looking for end points beginning from start) -->
	<xsl:param name="width_sum" select="0"/> <!-- sum of element widths between start and current -->
	<xsl:param name="stretch_sum" select="0"/> <!-- sum of element stretchabilities between start and current -->
	<xsl:param name="shrink_sum" select="0"/> <!-- sum of element shrinkabilities between start and current -->
	<xsl:param name="paragraph"/> <!-- paragraph containing the elements for which branches are added -->
	<xsl:param name="best_end"/> <!-- best branch ending position since the last encounted box -->
	<xsl:param name="best_ratio"/> <!-- ratio assiciated with the best branch ending position since the last encounted box -->
	<xsl:param name="best_cost"/> <!-- cost assiciated with the best branch ending position since the last encounted box -->
	
	<!-- find the line width for this paragraph -->
	<xsl:variable name="line_width">
		<xsl:choose>
			<xsl:when test="$paragraph/@line-width">
				<xsl:value-of select="$paragraph/@line-width"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$doc_line_width"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!-- check whether the end position is not too far (out of the bounds of the paragraph elements,
	or further than permitted by the line width and shinkabilities), if yes, research the end position and do a recursive call,
	if no, write the best found branch since the last encounted box and stop -->
	<xsl:choose>
		<xsl:when test="$current &lt;= count($paragraph/*) and ($width_sum - $shrink_sum &lt;= $line_width)">
			<!-- Research the current end position, get the element, update the width sum, stretch sum, shrink sum and get the element penalty -->
			<xsl:variable name="currentEl" select="$paragraph/*[$current]" />
			<xsl:variable name="current_width_sum">
				<xsl:choose>
					<xsl:when test="$currentEl/@width">
						<xsl:value-of select="$width_sum + number($currentEl/@width)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$width_sum"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="current_stretch_sum">
				<xsl:choose>
					<xsl:when test="$currentEl/@stretchability">
						<xsl:choose>
							<xsl:when test="$stretch_sum = 'INF' or $currentEl/@stretchability = 'INF'">
								<xsl:value-of select="'INF'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$stretch_sum + $currentEl/@stretchability"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$stretch_sum"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="current_shrink_sum">
				<xsl:choose>
					<xsl:when test="$currentEl/@shrinkability">
						<xsl:value-of select="$shrink_sum + $currentEl/@shrinkability"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$shrink_sum"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="current_penalty">
				<xsl:choose>
					<xsl:when test="name($currentEl) = 'penalty'">
						<xsl:value-of select="$currentEl/@penalty"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="0"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<!-- invalidate the best ending position found since the last box if the current element is a box -->
			<xsl:variable name="invalidate" select="name($currentEl) = 'box'"/>
			<xsl:if test="$best_end and $invalidate">
				<!-- if there was such an end position, this means that we should write it -->
				<xsl:call-template name="writeBranch">
					<xsl:with-param name="previous" select="$previous"/>
					<xsl:with-param name="start" select="$start"/>
					<xsl:with-param name="end" select="$best_end"/>
					<xsl:with-param name="ratio" select="$best_ratio"/>
					<xsl:with-param name="cost" select="$best_cost"/>
				</xsl:call-template>
			</xsl:if>
	
			<!-- Check whether it is possible to add a branch with current as an ending position. This is the case when the sum of stretchabilities is positive
			(normally always true for our examples, but we want to be generic), when this is permitted by the shrinkability and when the current element is a box
			which is not followed by a penalty or a penalty which is not +INF. -->
			<xsl:choose>
				<xsl:when test="(($current_stretch_sum = 'INF') or ($current_stretch_sum &gt; 0))
					and ($current_width_sum - $current_shrink_sum &lt;= $line_width)
					and not($current = $start)
					and ((name($currentEl) = 'box' and not(name($paragraph/*[$current+1]) = 'penalty')) or (name($currentEl) = 'penalty' and not($currentEl/@penalty = 'INF')))">
					<!-- Calculate the raio and cost for a branch with current as an ending point-->
					<xsl:variable name="current_ratio">
						<xsl:choose>
							<xsl:when test="$current_width_sum &lt; $line_width">
								<xsl:choose>
									<xsl:when test="$stretch_sum = 'INF'">
										<xsl:value-of select="0"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="($line_width -$current_width_sum) div $stretch_sum"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$current_width_sum = $line_width">
								<xsl:value-of select="0"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="($line_width -$current_width_sum) div $shrink_sum"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- current_ratioPositive is abs(current_ratio) -->
					<xsl:variable name="current_ratioPositive">
						<xsl:choose>
							<xsl:when test="$current_ratio &lt; 0">
								<xsl:value-of select="-current_ratio"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$current_ratio"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="current_cost">
						<xsl:choose>
							<xsl:when test="$current_penalty = 'INF'">
								<xsl:value-of select="'INF'"/>
							</xsl:when>
							<xsl:when test="$current_penalty = '-INF'">
								<xsl:value-of select="'-INF'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="floor(100*$current_ratioPositive*$current_ratioPositive*$current_ratioPositive+0.5) + $current_penalty"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- Check whether this ending point has the lowest cost since the last encountered box -->
					<xsl:choose>
						<xsl:when test="$invalidate or $current_cost='-INF' or $current_cost &lt; $best_cost">
							<!-- This element has the lowest cost -->
							<xsl:call-template name="find_end">
								<xsl:with-param name="previous" select="$previous"/>
								<xsl:with-param name="start" select="$start"/>
								<xsl:with-param name="current" select="$current + 1"/>
								<xsl:with-param name="width_sum" select="$current_width_sum"/>
								<xsl:with-param name="stretch_sum" select="$current_stretch_sum"/>
								<xsl:with-param name="shrink_sum" select="$current_shrink_sum"/>
								<xsl:with-param name="paragraph" select="$paragraph"/>
								<xsl:with-param name="best_end" select="$current"/>
								<xsl:with-param name="best_ratio" select="$current_ratio"/>
								<xsl:with-param name="best_cost" select="$current_cost"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<!-- The previously found ending position remains better -->
							<xsl:call-template name="find_end">
								<xsl:with-param name="previous" select="$previous"/>
								<xsl:with-param name="start" select="$start"/>
								<xsl:with-param name="current" select="$current + 1"/>
								<xsl:with-param name="width_sum" select="$current_width_sum"/>
								<xsl:with-param name="stretch_sum" select="$current_stretch_sum"/>
								<xsl:with-param name="shrink_sum" select="$current_shrink_sum"/>
								<xsl:with-param name="paragraph" select="$paragraph"/>
								<xsl:with-param name="best_end" select="$best_end"/>
								<xsl:with-param name="best_ratio" select="$best_ratio"/>
								<xsl:with-param name="best_cost" select="$best_cost"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<!-- This is not a suitable branch ending position. Recurse with previously found
					best ending position since the last encounted box or not, depending on whether the current element is a box. -->
					<xsl:choose>
						<xsl:when test="$invalidate">
							<!-- The current element is a box. The previously found end is invalidated. -->
							<xsl:call-template name="find_end">
								<xsl:with-param name="previous" select="$previous"/>
								<xsl:with-param name="start" select="$start"/>
								<xsl:with-param name="current" select="$current + 1"/>
								<xsl:with-param name="width_sum" select="$current_width_sum"/>
								<xsl:with-param name="stretch_sum" select="$current_stretch_sum"/>
								<xsl:with-param name="shrink_sum" select="$current_shrink_sum"/>
								<xsl:with-param name="paragraph" select="$paragraph"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<!-- The current element is not a box. The previously found remains valid. -->
							<xsl:call-template name="find_end">
								<xsl:with-param name="previous" select="$previous"/>
								<xsl:with-param name="start" select="$start"/>
								<xsl:with-param name="current" select="$current + 1"/>
								<xsl:with-param name="width_sum" select="$current_width_sum"/>
								<xsl:with-param name="stretch_sum" select="$current_stretch_sum"/>
								<xsl:with-param name="shrink_sum" select="$current_shrink_sum"/>
								<xsl:with-param name="paragraph" select="$paragraph"/>
								<xsl:with-param name="best_end" select="$best_end"/>
								<xsl:with-param name="best_ratio" select="$best_ratio"/>
								<xsl:with-param name="best_cost" select="$best_cost"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:otherwise>
			<!-- The current position is too far to be a valid end position. Write a branch with the best found ending point
			since the last encountered box and stop the recursion. -->
			<xsl:if test="$best_end">
				<xsl:call-template name="writeBranch">
					<xsl:with-param name="previous" select="$previous"/>
					<xsl:with-param name="start" select="$start"/>
					<xsl:with-param name="end" select="$best_end"/>
					<xsl:with-param name="ratio" select="$best_ratio"/>
					<xsl:with-param name="cost" select="$best_cost"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- This template writes a branch element -->
<xsl:template name="writeBranch">
	<xsl:param name="previous"/>
	<xsl:param name="start"/>
	<xsl:param name="end"/>
	<xsl:param name="ratio"/>
	<xsl:param name="cost"/>
	<branch>
		<xsl:attribute name="previous">
			<xsl:value-of select="$previous"/>
		</xsl:attribute>
		<xsl:attribute name="start">
			<xsl:value-of select="$start"/>
		</xsl:attribute>
		<xsl:attribute name="end">
			<xsl:value-of select="$end"/>
		</xsl:attribute>
		<xsl:attribute name="ratio">
			<xsl:value-of select="$ratio"/>
		</xsl:attribute>
		<xsl:attribute name="cost">
			<xsl:value-of select="$cost"/>
		</xsl:attribute>
	</branch>
</xsl:template>
</xsl:transform>