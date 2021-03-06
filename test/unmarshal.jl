using Unmarshal
using JSON
using Base.Test
import Base.==

#Tests for various type of composite structures, including Nullables
input = "{ \"bar\": { \"baz\": 17 }, \"foo\": 3.14 }"

immutable Bar
    baz::Int
end

immutable Foo
    bar::Bar
end

immutable Baz
    foo::Nullable{Float64}
    bar::Bar
end

immutable Qux
    baz::Nullable{String}
    bar::Bar
end


@test Unmarshal.unmarshal(Foo, JSON.parse(input)) === Foo(Bar(17))
@test Unmarshal.unmarshal(Baz, JSON.parse(input)) === Baz(Nullable(3.14), Bar(17))
@test Unmarshal.unmarshal(Qux, JSON.parse(input)) === Qux(Nullable{String}(),Bar(17))
@test_throws ArgumentError Unmarshal.unmarshal(Bar, JSON.parse(input)) 

#Test for structures of handling 1-D arrays
type StructOfArrays
        a1 :: Array{Float32, 1}
        a2 :: Array{Int, 1}
    end

function ==(A :: StructOfArrays, B :: StructOfArrays)
    A.a1 == B.a1 && A.a2 == B.a2
end

tmp = StructOfArrays([0,1,2], [1,2,3])
jstring = JSON.json(tmp)
@test Unmarshal.unmarshal(StructOfArrays, JSON.parse(jstring)) == tmp

#Test for handling 2-D arrays
type StructOfArrays2D
        a3 :: Array{Float64, 2}
        a4 :: Array{Int, 2}
    end

function ==(A :: StructOfArrays2D, B :: StructOfArrays2D)
    A.a3 == B.a3 && A.a4 == B.a4
end

tmp2 = StructOfArrays2D(ones(Float64, 2, 3), eye(Int, 2, 3))
jstring = JSON.json(tmp2)
@test Unmarshal.unmarshal(StructOfArrays2D, JSON.parse(jstring))  == tmp2

#Test for handling N-D arrays
tmp3 = randn(Float64, 2, 3, 4)
jstring = JSON.json(tmp3)
@test Unmarshal.unmarshal(Array{Float64, 3}, JSON.parse(jstring))  == tmp3

#Test for handling arrays of composite entities
tmp4 = Array{Array{Int,2}}(2)

tmp4[1] = ones(Int, 3, 4)
tmp4[2] = zeros(Int, 1, 2)
tmp4
jstring = JSON.json(tmp4)
@test Unmarshal.unmarshal(Array{Array{Int,2}}, JSON.parse(jstring)) == tmp4

# Test to check handling of complex numbers
tmp5 = zeros(Float32, 2) + 1im * ones(Float32, 2)
jstring = JSON.json(tmp5)
@test Unmarshal.unmarshal(Array{Complex{Float32}}, JSON.parse(jstring)) == tmp5

tmp6 = zeros(Float32, 2, 2) + 1im * ones(Float32, 2, 2)
jstring = JSON.json(tmp6)
@test Unmarshal.unmarshal(Array{Complex{Float32},2}, JSON.parse(jstring)) == tmp6

# Test to see handling of abstract types
type reconfigurable{T}
    x :: T
    y :: T
    z :: Int
end

function =={T1, T2}(A :: reconfigurable{T1}, B :: reconfigurable{T2})
    T1 == T2 && A.x == B.x && A.y == B.y && A.z == B.z
end


type higherlayer
    val :: reconfigurable
end

val = reconfigurable(1.0, 2.0, 3)
jstring = JSON.json(val)
@test Unmarshal.unmarshal(reconfigurable{Float64}, JSON.parse(jstring)) == reconfigurable{Float64}(1.0, 2.0, 3)

higher = higherlayer(val)
jstring = JSON.json(higher)
@test_throws ArgumentError Unmarshal.unmarshal(higherlayer, JSON.parse(jstring))

# Test string pass through
@test Unmarshal.unmarshal(String, JSON.parse(json("Test"))) == "Test"

# Test the verbose option
@test Unmarshal.unmarshal(Foo, JSON.parse(input), true) === Foo(Bar(17))
jstring = JSON.json(tmp3)
@test Unmarshal.unmarshal(Array{Float64, 3}, JSON.parse(jstring), true)  == tmp3

@test Unmarshal.unmarshal(String, JSON.parse(json("Test")), true) == "Test"

# Added test cases to attempt getting 100% code coverage
@test isequal(unmarshal(Nullable{Int64}, Void()), Nullable{Int64}())

@test_throws ArgumentError unmarshal(Nullable{Int64}, ones(Float64, 1))

# Test handling of Tuples
testTuples = ((1.0, 2.0, 3.0, 4.0), (2.0, 3.0))
jstring = JSON.json(testTuples)
@test Unmarshal.unmarshal(Tuple{Tuple{Float64}}, JSON.parse(jstring)) == testTuples
@test Unmarshal.unmarshal(Tuple{Array{Float64}}, JSON.parse(jstring)) == (([testElement...] for testElement in testTuples)...)
@test Unmarshal.unmarshal(Array{Tuple{Float64}}, JSON.parse(jstring)) == [testTuples...]
@test Unmarshal.unmarshal(Array{Array{Float64}}, JSON.parse(jstring)) == [([testElement...] for testElement in testTuples)...]
@test Unmarshal.unmarshal(Tuple{Tuple{Float64}}, JSON.parse(jstring), true) == testTuples


mutable struct DictTest
testDict::Dict{Int, String}
end

function ==(D1 :: DictTest, D2 :: DictTest)
    for iter in keys(D1.testDict)
        if !(D1.testDict[iter] == D2.testDict[iter])
          return false
        end
    end
    for iter in keys(D2.testDict)
        if !(D1.testDict[iter] == D2.testDict[iter])
          return false
        end
    end

    true
end

dictTest = DictTest(Dict{Int, String}(1 => "Test1", 2 => "Test2"))

#@show JSON.json(dictTest)
#@show JSON.parse(JSON.json(dictTest))
@test Unmarshal.unmarshal(DictTest, JSON.parse(JSON.json(dictTest)),true) == dictTest



