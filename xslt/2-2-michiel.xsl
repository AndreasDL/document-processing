<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <!--
       
    In this stylesheet the possible branches are calculated. Because of the preprocessing
    step (2-1.xsl), this can easily be done by 'walking' over the entire paragraph:
    
    The 'index' will traverse word by word through the paragraph. If the index is at a box
    element (a branch will always start with a box) all branches for this possible starting
    point are calculated. A branch always ends at an element with an optional break. If the
    ratio is smaller than zero, the process will restart at the next index value.
    
    Note that this step is (just like all other steps, except for step 1) independent of 
    the alignment of the paragraph.
        
    -->
    
    <!-- Indicate that the output is also an xml file -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>
    
    <xsl:template match="document|@*">
        <xsl:copy>
            <!-- write the element attributes (@*) -->
            <xsl:apply-templates select="@*"/>
            
            <!-- perform operations on paragraph elements -->
            <xsl:apply-templates select="paragraph">
                <xsl:with-param name="linewidth" select="@line-width"/>
            </xsl:apply-templates>
            
        </xsl:copy>
    </xsl:template>
    
    <!-- this template matches the paragraph element -->
    <xsl:template match="document/paragraph">
        <xsl:param name="linewidth"/>
        
        <xsl:copy>
            <!-- write the paragraph attributes -->
            <xsl:apply-templates select="@*"/>
            
            <!-- copy the content of step 1 between the content tags -->
            <content>
                <xsl:copy-of select="node()"/>
            </content>
            
            <!-- place branches tags and calculate branches cost and ratio -->
            <branches>
               
               <!-- Call the template to start calculating the branches -->
                <xsl:call-template name="create_branches">
                    
                    <!-- The nodes contain all elements (glues, boxes and penalties) of the paragraph -->
                    <xsl:with-param name="nodes" select="*"/>
                    
                    <!-- Calculation starts at the beginning of the paragraph -->
                    <xsl:with-param name="index" select="1"/>
                    <xsl:with-param name="counter" select="1"/>
                    
                    <!-- Since there are no previous breaks, this is set to 0 -->
                    <xsl:with-param name="previous_break" select="0"/>
                    
                    <!-- new_break will store the first possible breakpoint encountered when calculating
                        branches. The next iteration will start at this index. It is set at -1 until the
                        next breakpoint is found. -->
                    <xsl:with-param name="new_break" select="-1"/>
                    
                    <!-- The Lj, Yj and Zj values are initialized at 0... -->
                    <xsl:with-param name="Lj" select="0"/>
                    <xsl:with-param name="Yj" select="0"/>
                    <xsl:with-param name="Zj" select="0"/>
                    
                    <!-- xsl:choose in order to support paragraphs with different linewidths... -->
                    <xsl:with-param name="linewidth">
                        <xsl:choose>
                            <xsl:when test="string-length(@line-width)">
                                <xsl:value-of select="@linewidth"/>>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$linewidth"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    
                </xsl:call-template>
               
            </branches>			
            
        </xsl:copy>
    </xsl:template>
    
    <!-- This template will recursively iterate over the paragraphs and write out the possible branches -->
    <xsl:template name="create_branches">
        <xsl:param name="nodes"/>
        <xsl:param name="linewidth"/>
        <xsl:param name="index"/>
        <xsl:param name="counter"/>
        <xsl:param name="previous_break"/>
        <xsl:param name="new_break"/>
        <xsl:param name="Lj"/>
        <xsl:param name="Yj"/>
        <xsl:param name="Zj"/>
        
        <xsl:choose>
            
            <!-- We should start at the first box after the previous breakpoint (or on the first line),
                    therefore, we loop through the text and look for the next box... -->
            <xsl:when test="not($index = 1) and not(name($nodes[position() = $index]) = 'box')">
                <xsl:call-template name="create_branches">
                    <xsl:with-param name="nodes" select="$nodes"/>
                    <xsl:with-param name="linewidth" select="$linewidth"/>
                    <xsl:with-param name="index" select="$index + 1"/>
                    <xsl:with-param name="counter" select="$counter + 1"/>
                    <xsl:with-param name="previous_break" select="$previous_break"/>
                    <xsl:with-param name="new_break" select="$new_break"/>
                    <xsl:with-param name="Lj" select="0"/>
                    <xsl:with-param name="Yj" select="0"/>
                    <xsl:with-param name="Zj" select="0"/>
                </xsl:call-template>
            </xsl:when>
            
            <!-- If the index is at a box element, we can start (or continue) calculating branches starting from this element. -->
            <xsl:otherwise>

                <!-- Calculate the new Lj value -->
                <xsl:variable name="Lj_new">
                    <xsl:choose>
                        
                        <!-- If the current element (at index $counter) is a glue, add the width of this element -->
                        <xsl:when test="name($nodes[position() = $counter]) = 'glue'
                            or name($nodes[position() = $counter]) = 'box'">
                            <xsl:value-of select="$Lj + $nodes[position() = $counter]/@width"/>
                        </xsl:when>
                        
                        <!-- If the current element (at index $counter) is neither a glue or a box, the value will stay the same -->
                        <xsl:otherwise>
                            <xsl:value-of select="$Lj"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- Calculate the new Yj value -->
                <xsl:variable name="Yj_new">
                    <xsl:choose>
                        
                        <!-- If the current element (at index $counter) is a glue, add the stretchability -->
                        <xsl:when test="name($nodes[position() = $counter]) = 'glue'">
                            <xsl:choose>
                                
                                <!-- When adding INF, the value is hard coded to 'INF' -->
                                <xsl:when test="$nodes[position() = $counter]/@stretchability = 'INF'">
                                    <xsl:value-of select="'INF'"/>
                                </xsl:when>
                                
                                <!-- When adding -INF, the value is hard coded to '-INF' -->
                                <xsl:when test="$nodes[position() = $counter]/@stretchability = '-INF'">
                                    <xsl:value-of select="'-INF'"/>
                                </xsl:when>
                                
                                <!-- Otherwise, if the glue has a numerical stretchability, calculate the sum... -->
                                <xsl:otherwise>
                                    <xsl:value-of select="$Yj + $nodes[position() = $counter]/@stretchability"/>
                                </xsl:otherwise>
                                
                            </xsl:choose>
                        </xsl:when>
                        
                        <!-- If the current element (at index $counter) is not a glue, the value will stay the same -->
                        <xsl:otherwise>
                            <xsl:value-of select="$Yj"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- Calculate the new Zj value -->
                <xsl:variable name="Zj_new">
                    <xsl:choose>
                        
                        <!-- If the current element (at index $counter) is a glue, add the shrinkability -->
                        <xsl:when test="name($nodes[position() = $counter]) = 'glue'">
                            <xsl:value-of select="$Zj + $nodes[position() = $counter]/@shrinkability"/>
                        </xsl:when>
                        
                        <!-- If the current element (at index $counter) is not a glue, the value will stay the same -->
                        <xsl:otherwise>
                            <xsl:value-of select="$Zj"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <!-- Calculate the ratio -->
                <xsl:variable name="ratio">
                    <xsl:choose>
                        
                        <!-- When Lj equals the linewidth, the ratio is 0... -->
                        <xsl:when test="$linewidth - $Lj_new = 0">
                            <xsl:value-of select="0"/>
                        </xsl:when>
                        
                        <!-- Lj is smaller than the linewidth... -->
                        <xsl:when test="$Lj_new &lt; $linewidth">
                            <xsl:choose>
                                
                                <!-- If the stretchabilities are infinite, the ratio will be 0... -->
                                <xsl:when test="$Yj_new = 'INF' or $Yj_new = '-INF'">
                                    <xsl:value-of select="0"/>
                                </xsl:when>
                                
                                <!-- If the stretchabilities are greater than 0 (and not infinite), calculate the ratio... -->
                                <xsl:when test="$Yj_new &gt; 0">
                                    <xsl:value-of select="($linewidth - ($Lj_new)) div $Yj_new"/>
                                </xsl:when>
                                
                                <!-- In any other case, set the ratio to 'NaN' -->
                                <xsl:otherwise>
                                    <xsl:value-of select="'NaN'"/>
                                </xsl:otherwise>
                                
                            </xsl:choose>
                        </xsl:when>
                        
                        <!-- When Lj is greater than the linewidth, the ratio will be negative.
                            For simplicity reasons, this will not be calculated and a value of 'negative' is chosen instead. -->
                        <xsl:when test="$Lj_new &gt; $linewidth">
                            <xsl:value-of select="'negative'"/>
                        </xsl:when>
                        
                    </xsl:choose>
                </xsl:variable>

                <!-- Define the cost -->
                <xsl:variable name="cost">
                    <xsl:choose>
                        
                        <!-- When the ratio is 0 or the penalty -INF, set the cost to -INF -->
                        <xsl:when test="$ratio = 0 or $nodes[position() = $counter]/@penalty = '-INF'">
                            <!--<xsl:value-of select="'-INF'"/>-->
                            <!-- A cost of -INF will cause that a random branch is chosen at the end of the paragraph
                                (for example, 5 - INF is the same as 1 - INF). Therefore a value of 0 is chosen instead of -INF. -->
                            <xsl:value-of select="0"/>
                        </xsl:when>
                        
                        <!-- Set the cost to INF when the ratio is (-)INF, < -1 or 'NaN'... --> 
                        <xsl:when test="$ratio = 'NaN' or $ratio = 'INF' or $ratio = '-INF' or $ratio &lt; -1">
                            <xsl:value-of select="'INF'"/>
                        </xsl:when>
                        
                        <!-- In all other cases, calculate the cost... -->
                        <xsl:otherwise>
                            <xsl:value-of select="floor(100 * $ratio * $ratio * $ratio + 0.5)"/>
                        </xsl:otherwise>
                        
                    </xsl:choose>			
                </xsl:variable>
                
                <!-- Should a branch be written? Store this in the 'writebranch' variable that will be 1 or 0... -->
                <xsl:variable name="writebranch">
                    <xsl:choose>
                        
                        <!-- We will only write a branch if we are at an optional or required break
                            AND the ratio is not 'negative' or NaN... -->
                        <xsl:when test="($nodes[position() = $counter]/@break = 'required'
                            or $nodes[position() = $counter]/@break = 'optional')
                            and not($ratio = 'NaN') and not($ratio = 'negative')
                            and not($counter = $index)">
                            <xsl:value-of select="1"/>
                        </xsl:when>
                        
                        <xsl:otherwise>
                            <xsl:value-of select="0"/>
                        </xsl:otherwise>
                        
                    </xsl:choose>
                </xsl:variable>
                
                <!-- If a branch should be written, write a branch... 
                    
                    Branches will contain the following attributes:
                        - ratio
                        - cost
                        - start: the first element of the branch
                        - end: the last element of the branch
                        - previous: the last element of the branch that ended before this branch
                -->
                <xsl:if test="$writebranch = 1">
                    <branch>
                        <xsl:choose>
                            <xsl:when test="$ratio = 0">
                                <xsl:attribute name="cost">
                                    <!-- A cost of -INF will cause that a random branch is chosen at the end of the paragraph
                                (for example, 5 - INF is the same as 1 - INF). Therefore a value of 0 is chosen instead of -INF. -->
                                    <xsl:value-of select="0"/>
                                </xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="cost">
                                    <xsl:value-of select="format-number($cost, '#')"/>
                                </xsl:attribute>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                        <xsl:attribute name="ratio">
                            <xsl:value-of select="$ratio"/>
                        </xsl:attribute>	
                        <xsl:attribute name="start">
                            <xsl:value-of select="$index"/>
                        </xsl:attribute>
                        <xsl:attribute name="end">
                            <xsl:value-of select="$counter"/>
                        </xsl:attribute>
                        <xsl:attribute name="previous">
                            <xsl:value-of select="$previous_break"/>
                        </xsl:attribute>
                    </branch>
                </xsl:if>
                
                <xsl:choose>
                
                    <!-- Continue with the recursion if we're not at the end of the paragraph... -->
                    <xsl:when test="$ratio &lt; 0 or $ratio = 'negative' or $nodes[position() = $counter]/@break = 'required'">
                        
                        <!-- If no new next breakpoint was encountered, we are at the end of the paragraph ==> Stop -->
                        <xsl:if test="not($new_break = -1)">
                            <xsl:call-template name="create_branches">
                                <xsl:with-param name="nodes" select="$nodes"/>
                                <xsl:with-param name="linewidth" select="$linewidth"/>
                                
                                <!-- Restart 1 element after the break before the previous start... --> 
                                <xsl:with-param name="index" select="$new_break + 1"/>
                                <xsl:with-param name="counter" select="$new_break + 1"/>
                                
                                <!-- The new 'previous' index in the branches will be the 'new_break' index -->
                                <xsl:with-param name="previous_break" select="$new_break"/>
                                <xsl:with-param name="new_break" select="-1"/>
                                
                                <!-- The element at 'new_break' might be the first element of a new set of branches.
                                    Therefore, we initialize the Lj value with the the current box or glue width if necessary. -->
                                <xsl:with-param name="Lj">
                                    <xsl:choose>
                                        <xsl:when test="name($nodes[position() = $new_break]) = 'box'
                                            or name($nodes[position() = $new_break]) = 'glue'">
                                            <xsl:value-of select="$nodes[position() = $new_break]/@width"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="0"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:with-param>
                                
                                <!-- The element at 'new_break' might be the first element of a new set of branches.
                                    Therefore, we initialize the Yj value with the the current glue stretchability if necessary. -->
                                <xsl:with-param name="Yj">
                                    <xsl:choose>
                                        <xsl:when test="name($nodes[position() = $new_break]) = 'glue'">
                                            <xsl:value-of select="$nodes[position() = $new_break]/@stretchability"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="0"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:with-param>
                                
                                <!-- The element at 'new_break' might be the first element of a new set of branches.
                                    Therefore, we initialize the Zj value with the the current glue shrinkability if necessary. -->
                                <xsl:with-param name="Zj">
                                    <xsl:choose>
                                        <xsl:when test="name($nodes[position() = $new_break]) = 'glue'">
                                            <xsl:value-of select="$nodes[position() = $new_break]/@shrinkability"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="0"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:with-param>
                                
                            </xsl:call-template>
                            </xsl:if>                                
                        
                    </xsl:when>
                    
                    <!-- If we are not yet at the end of the paragraph, continue the recursion... -->
                    <xsl:otherwise>                            
                        <xsl:call-template name="create_branches">
                            <xsl:with-param name="nodes" select="$nodes"/>
                            <xsl:with-param name="linewidth" select="$linewidth"/>
                            
                            <!-- Since we are still looking at the same word, the index will remain the same -->
                            <xsl:with-param name="index" select="$index"/>
                            
                            <!-- The counter will be incremented -->
                            <xsl:with-param name="counter" select="$counter + 1"/>
                            
                            <!-- Since we are still looking at the same word, the previous_break will remain the same -->
                            <xsl:with-param name="previous_break" select="$previous_break"/>
                            
                            <!-- Pass the new Lj, Yj and Zj values -->
                            <xsl:with-param name="Lj" select="$Lj_new"/>
                            <xsl:with-param name="Yj" select="$Yj_new"/>
                            <xsl:with-param name="Zj" select="$Zj_new"/>
                             
                            <xsl:with-param name="new_break">
                                <xsl:choose>
                                    
                                    <!-- If the new_break value, the next index, was not yet found (at an optional or required break),
                                        we will check if the 'current' counter value might be the new_break value... --> 
                                    <xsl:when test="$new_break = -1">
                                        <xsl:choose>
                                            
                                            <!-- If the current element has an optional or required break, this is the new_break index -->
                                            <xsl:when test="($nodes[position() = $counter]/@break = 'optional'
                                                or $nodes[position() = $counter]/@break = 'required')"> 
                                                <!--and $counter &gt; $index">-->
                                                <xsl:value-of select="$counter"/>
                                            </xsl:when>
                                            
                                            <!-- Otherwise, the new_break value remains the same (-1) -->
                                            <xsl:otherwise>
                                                <xsl:value-of select="$new_break"/>
                                            </xsl:otherwise>
                                            
                                        </xsl:choose>
                                    </xsl:when>
                                    
                                    <!-- If the new_break value has already been set, keep the value... -->
                                    <xsl:otherwise>
                                        <xsl:value-of select="$new_break"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:with-param>
                           
                        </xsl:call-template>
                        
                    </xsl:otherwise>
                </xsl:choose>
            
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>    