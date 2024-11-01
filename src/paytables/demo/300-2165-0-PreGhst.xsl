<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						// IACGAA2E||M1                         - Division 1
						// 1ADAD2AD|W9,W11,Z,W6,W2,W1,W4,X|M4   - Division 3
						// BABAGBEA||                           - Division 13
						var scenario = getScenario(jsonContext);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var mainScenario = getOutcomeData(scenario);
						var bonusScenario = getBonusMoves(scenario);
						var symbolCountData = getPots();
						
						// Output winning numbers table.
						var r = [];
						var outcomeNum = 0;
						var bonusCount = 0;
						var multiplierCount = 0;

						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');

						r.push('<tr class="tablehead">');
						r.push('<td>');
						r.push(getTranslationByName("firework", translations));
						r.push('</td>');
						r.push('<td>');
						r.push(getTranslationByName("wins", translations));
						r.push('</td>');
						r.push('</tr>');

						for (var i = 0; i < mainScenario.length; i++)
						{
							symbolCountData = addToCountData(symbolCountData,mainScenario[i]);
						}

						for (var i in mainScenario)
						{
							r.push('<tr>');
						
							var prizeText = '';
							var playLetter = mainScenario[i];
							var winner = /[A-I]/.exec(playLetter);

							if (playLetter == '1')
							{
								bonusCount++;
							}
							else if (playLetter == '2')
							{
								multiplierCount++;
							}

							if (winner) 
							{
								r.push('<td class="tablebody">');
								r.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, playLetter)] + " " + prizeText);
								r.push('</td>');
								r.push('<td class="tablebody">');
								// for (var j in symbolCountData)
								for (var j = 0; j < symbolCountData.length; ++j)
								{
									if ((symbolCountData[j].count === 3) && (symbolCountData[j].letter === playLetter))
										r.push(getTranslationByName("youMatched", translations));
								}
								r.push('</td>');
							}
							else // either a 1 or a 2 so activates a bonus game
							{
								r.push('<td class="tablebody">');
								r.push(getTranslationByName(playLetter, translations));
								r.push('</td>');
								r.push('<td class="tablebody">');
								r.push('</td>');
							}

							r.push('</tr>');
						}
						r.push('</table>');

						if (bonusCount === 1)
						{
							r.push('<br>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');
							
							r.push('<tr class="tablehead">');
							r.push('<td>');
							r.push(getTranslationByName("bonusGame", translations));
							r.push('</td>');
							r.push('</tr>');

							r.push('<tr class="tablehead">');
							r.push('<td>');
							r.push(getTranslationByName("wheelPosition", translations));
							r.push('</td>');
							r.push('<td>');
							r.push(getTranslationByName("wins", translations));
							r.push('</td>');
							r.push('</tr>');

							for (var i in bonusScenario)
							{
								r.push('<tr>');
						
								var bonusPrize = "";
								var bonusPrizeLetter = bonusScenario[i][0];
								var bonusMatch = /[W]/.exec(bonusPrizeLetter);

								r.push('<td class="tablebody">');
								if (bonusMatch) 
								{
									bonusPrize = convertedPrizeValues[getPrizeNameIndex(prizeNames, bonusScenario[i])];
									r.push(bonusPrize);
								}
								else if (bonusPrizeLetter == 'X')
								{
									r.push(getTranslationByName("collect", translations));
								}
								else if (bonusPrizeLetter == 'Z')
								{
									r.push(getTranslationByName("wheelAdvance", translations));
								}
								r.push('</td>');
								if (bonusMatch) 
								{
									r.push('<td class="tablebody">');
									r.push(bonusPrize);
									r.push('</td>');
								}
								r.push('</tr>');
							}
							r.push('</table>');
						}

						if (multiplierCount === 1) 
						{
							var multiplier = getMultiplier(scenario);
							r.push('<br>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');
							
							r.push('<tr class="tablehead">');
							r.push('<td>');
							r.push(getTranslationByName("multiplierGame", translations));
							r.push('</td>');
							r.push('</tr>');

							r.push('<tr class="tablehead">');
							r.push('<td>');
							r.push("x" + multiplier + " " + getTranslationByName("totalWinnings", translations));
							r.push('</td>');
							r.push('</tr>');

							r.push('</table>');
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
								r.push('</td>');
								r.push('</tr>');
							}
							r.push('</table>');
							
						}
						
						return r.join('');
					}
					
					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");
						
						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}
						
						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}
					
					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A..I" and "W1..W11"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{						
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					// Input: "1ADAD2AD|W9,W11,Z,W6,W2,W1,W4,X|M4"
					// Output: ["1", "A", "D", "A", ...]
					function getOutcomeData(scenario)
					{
						var outcomeData = scenario.split("|")[0];
						return outcomeData.split("");
					}
					
					// Input: "1ADAD2AD|W9,W11,Z,W6,W2,W1,W4,X|M4"
					// Output: ["W9", "W11", "Z", ...]
					function getBonusMoves(scenario)
					{
						var bonusData = scenario.split("|")[1];
						var bonusPairs = bonusData.split(",");
						var result = [];
						for(var i = 0; i < bonusPairs.length; ++i)
						{
							result.push(bonusPairs[i]); 
						}
						return result;
					}

					function getMultiplier(scenario)
					{
						var multiplierValues = [10, 8, 6, 5, 4, 3, 2]; 
						var numsData = scenario.split("|")[2];
						var numVal = 0;
						if (numsData.length > 0) 
						{
							var multIndex = getMultiplierNameIndex(numsData);
							numVal = multiplierValues[multIndex];
						}
						return numVal;
					}

					// Input: "A..I" and "W1..W11"
					// Output: index number
					function getMultiplierNameIndex(multiplierName)
					{	
						var multiplierNames = ["M1", "M2", "M3", "M4", "M5", "M6", "M7"]; 
						for(var i = 0; i < multiplierNames.length; ++i)
						{
							if(multiplierNames[i] == multiplierName)
							{
								return i;
							}
						}
					}

					function getPots()
					{
						//Now get them split up individually
						var individualPots = ["A","B","C","D","E","F","G","H","I"];
						var symbolCountData = new Array(individualPots.length);
						for(var i = 0; i<individualPots.length; i++)
						{
							var singlePrize = {
								letter : individualPots[i].toString(),
								count : 0
							};
							symbolCountData[i] = singlePrize;
						}
						return symbolCountData;
					}

					function addToCountData(symbolCountData, letter)
					{
						for(var i = 0; i < symbolCountData.length; i++){
							if(symbolCountData[i].letter.toString() === letter.toString())
							{
								symbolCountData[i].count = symbolCountData[i].count + 1;
								break;
							}
						}
						return symbolCountData;
					}
					
					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					/////////////////////////////////////////////////////////////////////////////////////////

					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
