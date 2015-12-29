<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
  
    <xsl:output method="xml" indent="yes"/>

  <xsl:variable name="linewidth_general" select="document/@line-width" />
  
    <!-- standard code outputted by Visual Studio, is the default copy operator-->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

  <!-- Construct line breaking graph for each paragraph -->
  <xsl:template match="paragraph">
    <!-- start with getting the necessary variables -->
    <!-- Get the line width-->
    <xsl:variable name="linewidth">
      <xsl:choose>
        <xsl:when test="@line-width">
          <xsl:value-of select="@line-width"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$linewidth_general"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- We use a different copy here for the non-default behaviour of this template -->
    <paragraph>
      <xsl:apply-templates select="@*"/>

    <!-- Now, let's at an index to the files, this is not really necessary, but it is easier for debugging purposes -->
      <xsl:call-template name="output_content_with_indices">
        <xsl:with-param name="text" select="."/>
      </xsl:call-template>
      
    <!-- After the adding of the content and the indices, let's add the branches-->
      <xsl:call-template name="output_branches">
        <xsl:with-param name="text" select="."/>
        <xsl:with-param name="linewidth" select="$linewidth" />
      </xsl:call-template>
    </paragraph>
    
    
    
  </xsl:template>

  <!-- Here, the content is generated with an index added to each component-->
  <xsl:template name="output_content_with_indices">
    <xsl:param name="text"/>

    <content>
      <xsl:for-each select="./*">
        <xsl:copy>
          <!-- add the index for each box in the paragraph -->
          <xsl:attribute name="index">
            <xsl:value-of select="position()"/>
          </xsl:attribute>
          <!-- copy the other attributes and content as well -->
          <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
      </xsl:for-each>
    </content>
    
  </xsl:template>

  <!-- Here, the branches are added for the paragraph-->
  <xsl:template name="output_branches">
    <xsl:param name="text"/>
    <xsl:param name="linewidth"/>
    <!-- When is a break possible?
    1) You are positioned at a box without a penalty
    2) You are positioned at a penalty that is not prohibited
    3) The distance between the previous line break and the position where you want to break is compatible with the line width (and shrinkability) -->

    <!-- The algorithm will go as following:
    1) Start at the beginning of the paragraph
    2) add a branch for each possible breakpoint with as 'previous' position the start of the paragraph
    3) get to the next possible breakpoint, and redo step 2 with this possible breakpoint-->

    <!-- Open the branches tag-->
    <branches>
      <!-- Loop through all the elements of the paragraph-->
      
      <!-- This is the special case where we find branches starting at the very beginning of the paragraph-->
      <!-- We the node to the next function which will find all possible end nodes and add the branches in a recursive manner.-->
      <xsl:call-template name="check_end_node">
        <xsl:with-param name="previous" select="0"/>
        <xsl:with-param name="start" select="1"/>
        <xsl:with-param name="paragraph" select="."/>
        <xsl:with-param name="linewidth" select="$linewidth"/>
      </xsl:call-template>
      
      <xsl:for-each select="./*">
        <!-- first check if it is a valid possible breakpoint-->
        <xsl:if test="(name(.)='box' and not(name(following-sibling::*[1])='penalty')) or (name(.)='penalty' and not(@penalty='INF' or @break='prohibited'))">
        <!-- Now that we have a valid possible breakpoint/previous element, we can start to search for the start and end element-->
        <!-- We start with finding the start and previous element element-->

          <xsl:variable name="previous" select="position()"/>
          <xsl:variable name="start" select="count(following-sibling::*[name() = 'box'][1]/preceding-sibling::*)+1" />
          
          <!-- make sure that previous is positioned at a later index than start-->
          <xsl:if test="$start &gt; $previous">
            
          <!-- We now give these nodes to the next function which will find all possible end nodes and add the branches in a recursive manner.-->
          <xsl:call-template name="check_end_node">
            <xsl:with-param name="previous" select="$previous"/>
            <xsl:with-param name="start" select="$start"/>
            <xsl:with-param name="paragraph" select=".."/>
            <xsl:with-param name="linewidth" select="$linewidth"/>
          </xsl:call-template>

          </xsl:if>
        </xsl:if>
      </xsl:for-each>
      
    </branches>
  </xsl:template>

  <xsl:template name="check_end_node">
    <!-- is the first box after the previous index-->
    <xsl:param name="start"/>
    <!-- is the place of the previous breakpoint -->
    <xsl:param name="previous"/>
    <!-- All the content of the paragraph-->
    <xsl:param name="paragraph"/>
    <!-- the linewidth of the paragraph-->
    <xsl:param name="linewidth"/>
    <!-- the total width, stretchability and shrinkability, this is updated each time the end element index is increased -->
    <xsl:param name="total_width" select="0"/>
    <xsl:param name="total_stretchability" select="0" />
    <xsl:param name="total_shrinkability" select="0" />
    <!-- the end_position is the current positioin of a possible new breakpoint-->
    <xsl:param name="end_position" select="$start"/>
                  
    <!--1) get the current element, and calculate the new width, stretchability and shrinkability -->
    <!-- get current element-->
    <xsl:variable name="current_element" select="$paragraph/*[$end_position]"/>

    <!-- update the total width -->
    <xsl:variable name="new_total_width" >
      <xsl:choose>
        <!-- check if the element has a width attribute -->
        <xsl:when test="$current_element/@width">
          <xsl:value-of select="$total_width + $current_element/@width"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$total_width"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- update the total stretchability-->
    <xsl:variable name="new_total_stretchability" >
      <xsl:choose>
        <!-- test if the element has a stretchability attribute -->
        <xsl:when test="$current_element/@stretchability">
          <!-- We can not add strings to numbers, which can be the case when the value of stretchability is 'INF', so this needs to be taken into account -->
          <xsl:choose>
            <xsl:when test="$current_element/@stretchability='INF' or $total_stretchability='INF'">
              <xsl:value-of select="'INF'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$total_stretchability + $current_element/@stretchability"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$total_stretchability"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- update the total shrinkability -->
    <xsl:variable name="new_total_shrinkability" >
      <xsl:choose>
        <!-- check if the element has a shrinkability attribute-->
        <xsl:when test="$current_element/@shrinkability">
          <!-- We can not add strings to numbers, which can be the case when the value of shrinkability is 'INF', so this needs to be taken into account -->
          <xsl:choose>
            <xsl:when test="$current_element/@shrinkability='INF' or $total_shrinkability='INF'">
              <xsl:value-of select="'INF'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$total_shrinkability + $current_element/@shrinkability"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$total_shrinkability"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!--2) check if a branch can be made at the current element -->
    <!-- first check if is a point where a breakpoint can be done -->
    <xsl:if test="(name($current_element)='box' and not(name($paragraph[$end_position+1])='penalty')) or (name($current_element)='penalty' and not($current_element/@penalty='INF' or $current_element/@break='prohibited'))">
     
      <!-- calculate the ratio -->
      <xsl:variable name="ratio">
        <xsl:choose>
          <!-- implement the cases that are mentioned in the course, again implement special cases when a variable has the 'INF' value-->
          <xsl:when test="$linewidth=$new_total_width">
            <xsl:value-of select="0"/>
          </xsl:when>
          <xsl:when test="$linewidth &gt; $new_total_width">
            <xsl:if test="($new_total_stretchability &gt; 0) or ($new_total_stretchability='INF')">
              <xsl:choose>
                <xsl:when test="$new_total_stretchability='INF'">
                  <xsl:value-of select="0"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="($linewidth - $new_total_width) div $new_total_stretchability"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="($new_total_shrinkability &gt; 0) or ($new_total_shrinkability='INF')">
              <xsl:choose>
                <xsl:when test="$new_total_shrinkability='INF'">
                  <xsl:value-of select="0"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="($linewidth - $new_total_width) div $new_total_shrinkability"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- add the branch if the ratio is greater than -1-->
      <xsl:if test="$ratio &gt; -1">
        <!-- add the branch if a branch is found-->
        
        <!-- calculate the cost-->
        <xsl:variable name="abscost" select="($ratio*($ratio >=0) - $ratio*($ratio &lt; 0))"/>
        <xsl:variable name="spacecost">
          <xsl:value-of select="floor((100 * ($abscost * $abscost * $abscost)) + 0.5)"/>
        </xsl:variable>

        <!-- check if the breakpoint is a penalty. When this is the case, add the penalty cost to the total cost                                                 -->
        <xsl:variable name="cost">
          <xsl:choose>
            <xsl:when test="$current_element/@penalty">
              <xsl:choose>
                <xsl:when test="$current_element/@penalty='INF'">
                  <xsl:value-of select="'INF'"/>
                </xsl:when>
                <xsl:when test="$current_element/@penalty='-INF'">
                  <xsl:value-of select="'-INF'"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$current_element/@penalty + $spacecost"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$spacecost"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        
        <branch>
          <!--cost-->
          <xsl:attribute name="cost">
            <xsl:value-of select="$cost"/>
          </xsl:attribute>
          <!-- ratio -->
          <xsl:attribute name="ratio">
            <xsl:value-of select="$ratio"/>
          </xsl:attribute>
          <!-- previous is the current position (the possible breakpoint)-->
          <xsl:attribute name="previous">
            <xsl:value-of select="$previous"/>
          </xsl:attribute>
          <!-- start is the index of the first box element following the possible breakpoint-->
          <xsl:attribute name="start">
            <xsl:value-of select="$start"/>
          </xsl:attribute>
          <!-- end -->
          <xsl:attribute name="end">
            <xsl:value-of select="$end_position"/>
          </xsl:attribute>
        </branch>
      </xsl:if>
    </xsl:if>
    
    <!-- continue the recursion when possible-->

    <xsl:if test="($end_position &lt; count($paragraph/*)) and (($new_total_width - $new_total_shrinkability) &lt;= $linewidth)">
      
      <xsl:call-template name="check_end_node">
        <xsl:with-param name="start" select="$start"/>
        <xsl:with-param name="previous" select="$previous"/>
        <xsl:with-param name="paragraph" select="$paragraph"/>
        <xsl:with-param name="linewidth" select="$linewidth"/>
        <xsl:with-param name="total_width" select="$new_total_width"/>
        <xsl:with-param name="total_stretchability" select="$new_total_stretchability" />
        <xsl:with-param name="total_shrinkability" select="$new_total_shrinkability" />
        <xsl:with-param name="end_position" select="$end_position + 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
    
</xsl:stylesheet>
