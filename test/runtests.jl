using TaggedAxisArrays
using Test

a1 = TaggedAxisVector(1:4, Tag(1))
a2 = TaggedAxisVector(1:4, Tag(2))

@test_throws DimensionMismatch a1 .+ a2
@test a1 .+ a1 == TaggedAxisArray(parent(a1) .+ parent(a1), tags(a1))

# write tests here

## NOTE add JET to the test environment, then uncomment
# using JET
# @testset "static analysis with JET.jl" begin
#     @test isempty(JET.get_reports(report_package(TaggedAxisArrays, target_modules=(TaggedAxisArrays,))))
# end

## NOTE add Aqua to the test environment, then uncomment
# @testset "QA with Aqua" begin
#     import Aqua
#     Aqua.test_all(TaggedAxisArrays; ambiguities = false)
#     # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
#     Aqua.test_ambiguities(TaggedAxisArrays)
# end
