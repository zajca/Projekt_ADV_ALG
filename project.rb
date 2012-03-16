#!/usr/bin/ruby

def readFile fileName #reads file and return array of file
  if fileName.nil?
    puts "Insert file"
    puts "usage:"
    puts "bash project.sh <file input> <file output>"
    puts "or"
    puts "ruby project.rb <file input> <file output>"
    Kernel.exit
  end

  if FileTest::exist?(fileName)
     fileLines = IO.readlines(fileName)
  else
    puts "File is not exist"
    Kernel.exit
  end

  fileLines
end

def testOutFile fileName #test output file parameter
  if fileName.nil?
    puts "Insert output file"
    puts "usage:"
    puts "bash project.sh <file input> <file output>"
    puts "or"
    puts "ruby project.rb <file input> <file output>"
    Kernel.exit
  end
  return fileName
end

def normalizeFile fileLines #parse array and remove spaces, EOL and etc,...
  normalizedLines = []

  fileLines.each do |oneLine|
    oneLine = oneLine.gsub(/[^ULDR0-9<>\s]+/i, '')
    oneLine.split(' ')
    normalizedLines.push oneLine
  end
  finalData = []
  
  normalizedLines.each do |this_line|
    finalData << this_line.split(' ')
  end

  return finalData
end

def normalizeFinalFile fileLines #parse array and remove spaces, EOL and etc,...
	normalizedLines = []

	fileLines.each do |oneLine|
		normalizedLines.push oneLine
	end
	finalData = []

	normalizedLines.each do |this_line|
		finalData << this_line.split(' ')
	end

	return finalData
end

##
##function to testing input for many thinks
##
def testInput inputArray
  testDimensionBaseNumber inputArray

  dim = inputArray[0][0]
  puts "Dimensions: " + dim
  nOfSetNumbers = inputArray[1][0]
  puts "Number of given numbers: " + nOfSetNumbers
  
  testMaxValueEach(inputArray,1)
  
  lineOfNumberConstraints = (2 + nOfSetNumbers.to_i)
  
  testPositionOfAdditionalConstraints(inputArray, lineOfNumberConstraints)

  testMaxValueEach(inputArray, lineOfNumberConstraints)
  
  numberOfAdditionalConstraints = inputArray[lineOfNumberConstraints][0]
  
  puts "Number of given constraints: " + numberOfAdditionalConstraints
  
  if inputArray.length != (numberOfAdditionalConstraints.to_i+nOfSetNumbers.to_i+3)
      puts "wrong input file - number of lines is not matching with given numbers of constraints"
  end
  
  (2..(nOfSetNumbers.to_i+1)).each do |i|
    testNumberOfElements(inputArray,i,3)
  end

  (lineOfNumberConstraints+1..(numberOfAdditionalConstraints.to_i+lineOfNumberConstraints)).each do |i|
    testNumberOfElements(inputArray,i,4)
  end

  testValueOfElements(inputArray,dim, nOfSetNumbers,numberOfAdditionalConstraints)

  return dim
end
##
##Testes called by testInput
##

def testMaxValueEach(inputArray, line)
    dim = inputArray[0][0].to_i
    nOfSetNumbers = inputArray[line][0].to_i
    start=line+1
    ending=nOfSetNumbers+line
    testMaxValueEachCicle(inputArray, line, start, ending, dim)
end

def testMaxValueEachCicle(inputArray, line, start, ending, dim)
  (start..ending).each do |i|
      colNum = inputArray[i][1].to_i
      rowNum = inputArray[i][0].to_i
      if(line==1)
        intVal = inputArray[i][2].to_i
      else
        intVal = 1
      end
      testMaxValueEachCall(dim, colNum, rowNum, i+2, intVal)
    end
end
    
def testMaxValueEachCall(dim, colNum, rowNum, line, intVal)
  line=line-1
  if(colNum>dim or rowNum>dim or intVal>dim or colNum<1 or rowNum<1 or intVal<1)
    puts "Value of some element is bigger than maximum number Line: #{line}"
    Kernel.exit
  end
end

def testPositionOfAdditionalConstraints(inputArray, lineNumber)
  if inputArray[lineNumber].length != 1
    puts "input file error, Line N.#{lineNumber+1}"
    Kernel.exit
  end
end
  
def testDimensionBaseNumber inputArray
  if inputArray[0].length != 1
    puts "Input file is wrong - number of dimension is not OK, Line N.#{inputArray[0]}"
    Kernel.exit
  end

  if inputArray[1].length != 1
    puts "Input file is wrong - number of given number is not OK, Line N.#{inputArray[1]}"
    Kernel.exit
  end
end

def testNumberOfElements(inputArray, position, nElements)
  if inputArray[position].length != nElements
    puts "Input file wrong - some constraint is not OK, Line N.#{position+1}"
    Kernel.exit
  end
end

def testValueOfElements(inputArray, mAX_VAL, nSet,nCon)
	inputArray = inputArray.to_s.gsub(/[^0-9]/,'')
	#puts inputArray.to_s
end
##
##function printing file for Lp_solve
##
def printToLpFile inputArray
  outputFileName = 'outputForLpSolve.lp'
  outFile = File.new(outputFileName, 'w')
  
  outString = createObjFun(inputArray)  
  outFile.puts "//minimalization function"
  outFile.puts "min: "+ outString
  
  varMatrix = makeEmptyVarMatrix inputArray

  outString = createRowColCons(inputArray, varMatrix)
  outFile.puts "//constraints for rows and collumns"
  outFile.puts outString

  (boolMatrixRow, boolMatrixCol) = makeMatrixWithBool(varMatrix, inputArray)
  outString = createRowColBoolCons(boolMatrixRow, boolMatrixCol, varMatrix)
  outFile.puts "//constraints for rows and collumns"
  outFile.puts outString

  outString = createDefinedNumbers(inputArray,varMatrix)
  outFile.puts "//predefined numbers"
  outFile.puts outString

  outString = createAdditionalConstraints(inputArray,varMatrix)
  outFile.puts "//constraints between elements"
  outFile.puts outString

  outString = setEachVarConstraint(inputArray, varMatrix)
  outFile.puts "//variables limits"
  outFile.puts outString

  outString = setIntegers(varMatrix, boolMatrixRow, boolMatrixCol)
  outFile.puts "//defined integers"
  outFile.puts outString

  makeMatrixWithBool(varMatrix, inputArray)

  outFile.close
end

def createObjFun inputArray #return objective function
  numOfVar = inputArray[0][0].to_i
  numOfVar = numOfVar*numOfVar-1
  outString = String.new

  (0..numOfVar).each do |i|
    xNum = i.to_s
    if i == numOfVar
      outString += "x#{xNum};"  
    elsif i == 0
      outString = "x#{xNum} + "
    else
      outString += "x#{xNum} + "
    end
  end  
  return outString
end

def createRowColCons(inputArray, varMatrix) #return constraint for rows and collumns
  dim = inputArray[0][0].to_i
  outString = String.new
  outStringArr = []
  postInArr = 0
  sum = 0
  for i in 1..dim
    sum = sum+i 
  end
  for i in 1..dim
    for j in 1..dim
      if j != dim
        outString += varMatrix[i-1][j-1] + " + "
      else
        outString += varMatrix[i-1][j-1]
      end
    end
    outStringArr[postInArr] = "#{outString} = #{sum};"    
    postInArr = postInArr+1
    outString = ""
  end

for j in 1..dim
    for i in 1..dim
      if i != dim
        outString += varMatrix[i-1][j-1] + " + "
      else
        outString += varMatrix[i-1][j-1]
      end
    end
    outStringArr[postInArr] = "#{outString} = #{sum};"    
    postInArr = postInArr+1
    outString = ""
end

  return outStringArr
end

def createRowColBoolCons(boolMatrixRow, boolMatrixCol, varMatrix) # create constraints that in column and row can't be 2 same numbers
  outString = String.new
  outStringArr = []
  num = 0
  nBoolRow = boolMatrixRow[0].length
  numbersToCombinate = []
  dim = varMatrix[0].length

  for i in (0..(varMatrix[0].length-1))
    numbersToCombinate[i] = i
  end

  for i in (1..dim)
    count = 0
    numbersToCombinate.combination(2){|x|
          numberInLine1 = x[0]
          numberInLine2 = x[1]
          
          x1 = varMatrix[i-1][numberInLine1]
          x2 =varMatrix[i-1][numberInLine2]

          n = boolMatrixRow[i-1][count]
          count += 1
          o =boolMatrixRow[i-1][count]

          outString = "#{x1} - #{x2} + #{dim}*#{n} >= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString = "#{x2} - #{x1} + #{dim}*#{o} >= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString =  "0 <= #{n} <= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString = "0 <= #{o} <= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString = "#{n} + #{o} = 1;"
          outStringArr[num] = outString
          num = num + 1
          count +=1
    }
  end
  
for i in (1..dim)
    count = 0
    numbersToCombinate.combination(2){|x|
          numberInLine1 = x[0]
          numberInLine2 = x[1]
          
          x1 = varMatrix[numberInLine1][i-1]
          x2 =varMatrix[numberInLine2][i-1]
          n = boolMatrixCol[i-1][count]
          count += 1
          o =boolMatrixCol[i-1][count]
          count +=1
          outString = "#{x1} - #{x2} + #{dim}*#{n} >= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString = "#{x2} - #{x1} + #{dim}*#{o} >= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString =  "0 <= #{n} <= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString = "0 <= #{o} <= 1;"
          outStringArr[num] = outString
          num = num + 1
          outString = "#{n} + #{o} = 1;"
          outStringArr[num] = outString
          num = num + 1
    }
end

  return outStringArr
end

def createDefinedNumbers(inputArray, varMatrix) #return constraints for predefined numbers
    nOfSetNumbers = inputArray[1][0].to_i
    outStringArr = []

    (2..(nOfSetNumbers+1)).each do |i|
      colNum = inputArray[i][1].to_i
      rowNum = inputArray[i][0].to_i
      intVal = inputArray[i][2].to_i
      x = varMatrix[rowNum-1][colNum-1]
      outStringArr[i-2] = "#{x} = #{intVal};"
    end

  return outStringArr
end

def createAdditionalConstraints(inputArray, varMatrix) #return constraint between to elements
  dim = inputArray[0][0].to_i
  nOfSetNumbers = inputArray[1][0]  
  lineOfNumberConstraints = (2 + nOfSetNumbers.to_i)
  numberOfAdditionalConstraints = inputArray[lineOfNumberConstraints][0]
  outStringArr = []

  startP = lineOfNumberConstraints+1
  endP = lineOfNumberConstraints.to_i+numberOfAdditionalConstraints.to_i
  outP = 0
  (startP..endP).each do |i|
    relatedPosition = inputArray[i][3]
    x = inputArray[i][0].to_i-1
    y = inputArray[i][1].to_i-1
    testPositionOfCompared(x, y, relatedPosition, dim, i)
    (xC, yC) = setVarToCompare(x, y, relatedPosition)
    if inputArray[i][2] == "<"
      outStringArr[outP] = "#{varMatrix[x][y]} - #{varMatrix[xC][yC]} #{inputArray[i][2]}= -1;"
    else
      outStringArr[outP] = "#{varMatrix[x][y]} - #{varMatrix[xC][yC]} #{inputArray[i][2]}= 1;"
    end
    outP = outP+1
  end

  return outStringArr
end

def setVarToCompare(x, y, relatedPosition) #return x,y in inputArray which will be compared with another element
  if relatedPosition == "d"
    x = x+1
  elsif relatedPosition == "u"
    x = x-1
  elsif relatedPosition == "l"
    y = y-1
  elsif relatedPosition == "r"
    y = y+1
  end
  
  return x, y
end

def testPositionOfCompared(x, y, relatedPosition, dim, i) #testing if is posible to compare two elements
  dim = dim-1
    if relatedPosition == "d" and (x+1>dim or x<0)
      puts "wrong down constraint Line N.#{i+1}"
      Kernel.exit
    elsif relatedPosition == "u" and (x-1<0 or x>dim)
      puts "wrong up constraint Line N.#{i+1}"
      Kernel.exit
    elsif relatedPosition == "r" and (y+1>dim or y<0)
      puts "wrong right constraint Line N.#{i+1}"
      Kernel.exit
    elsif relatedPosition == "l" and (y-1<0 or y>dim)
      puts "wrong left constraint Line N.#{i+1}"
      Kernel.exit
    end

    if x>dim or y>dim or x<0 or y<0
      puts "wrong position number Line N.#{i+1}"
      Kernel.exit
    end
end

def setEachVarConstraint(inputArray, varMatrix) #setting constraint for each variable
  dim = inputArray[0][0].to_i
  num = 1
  outStringArr = []

  for i in 1..dim
    for j in 1..dim
      outStringArr[num-1] = "1 <= x#{num-1} <= #{dim};"
      num = num+1
    end   
  end
  return outStringArr
end

def setIntegers (varMatrix, boolMatrixRow, boolMatrixCol) #return set of integer for lp_solve
  outString = "int "

  varMatrix.each do |i|
    outString += "#{i.to_s.gsub(/[\[\]\"]/, '')}, "
  end  

  boolMatrixCol.each do |i|
    outString += "#{i.to_s.gsub(/[\[\]\"]/, '')}, "
  end

  boolMatrixRow.each do |i|
    outString += "#{i.to_s.gsub(/[\[\]\"]/, '')}, "
  end
  outString = outString[0..-3]
  outString += ";"
  return outString
end

def makeEmptyVarMatrix inputArray #return matrix with variables x0..xy
  dim = inputArray[0][0].to_i
  varMatrix = Array.new(dim).map!{ Array.new(dim) }
  num = 1

  for i in 1..dim
    for j in 1..dim
      varMatrix[i-1][j-1] = "x#{num-1}"
      num = num+1
    end   
  end

  return varMatrix
end

def makeMatrixWithBool(varMatrix,inputArray) #return matrix with variables c0..cy
  dim = inputArray[0][0].to_i
  boolN = 0
  (1..dim-1).each do |i|
    boolN = boolN + i
  end 

  num = 0
  boolMatrixRow = Array.new(dim).map!{ Array.new(dim) }
  for i in 1..dim
    for j in 1..(2*boolN)
      boolMatrixRow[i-1][j-1] = "c#{num}"
      num = num +1
    end   
  end

  boolMatrixCol = Array.new(dim).map!{ Array.new(dim) }
  for i in 1..dim
    for j in 1..(2*boolN)
      boolMatrixCol[i-1][j-1] = "c#{num}"
      num = num +1
    end   
  end
  return boolMatrixRow, boolMatrixCol
end

##
## functions for parsing LP_solve output
##
def parseOutFromLP_solve(inputArray, dim)
  if (inputArray.length==1)
    puts "LP solve output: " + inputArray.to_s.gsub(/[\[\]\,\"]/, '')
    Kernel.exit
  end

  objFuncVal = inputArray[1][4]
  outString = String.new
  dim = dim.to_i
  outStringArr = Array.new(dim).map!{ Array.new(dim) }
  num = 0
  xVal = 0

  for li in (0..(3+(dim*dim)))
      if li>3
        outString += "#{inputArray[li][1]} "
        if ((li-4) % (dim)) == 0
          xVal = xVal+1
          num = 0
        end
        outStringArr[xVal-1][num] = outString
        outString = ""
        num = num+1
      end
  end
  return outStringArr
end

def printResult(resultArr, dim, outputFileName)
  outFile = File.new(outputFileName, 'w')
  
  arrL = resultArr.length
  resString = String.new
  puts dim
  outFile.puts dim
  for line in 0..arrL
    resString = resultArr[line].to_s.gsub(/[\[\]\,\"]/, '')
    puts resString
    outFile.puts resString
    resString = ""
  end
  outFile.close
end
##
##main Function
##
system("clear")
arrayOfLines = readFile ARGV[0]
outputFile = testOutFile ARGV[1]
normarmalizedArray = normalizeFile arrayOfLines
dim = testInput normarmalizedArray
printToLpFile normarmalizedArray
system("lp_solve outputForLpSolve.lp>outFromLpSolve.txt")
arrayOfLines = readFile 'outFromLpSolve.txt'
normarmalizedArray = normalizeFinalFile arrayOfLines
parsedResult = parseOutFromLP_solve(normarmalizedArray, dim)
printResult(parsedResult, dim, outputFile)
##
##End of main function
##

