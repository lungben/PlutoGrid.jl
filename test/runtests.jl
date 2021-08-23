using PlutoGrid
using Test
using HypertextLiteral
using DataFrames

@testset "PlutoGrid.jl" begin
    df = DataFrame(x=1:10, y=10:-1:1)
	@test readonly_table(df) isa HypertextLiteral.Result

    nt = [(a=1, b=0.5, c="hello"), (a=2, b=0.9, c="world"), (a=3, b=5.5, c="!")]
    @test readonly_table(nt) isa HypertextLiteral.Result

    @test editable_table(nt) isa HypertextLiteral.Result
    @test editable_table(df, ["x"]) isa HypertextLiteral.Result
    @test_throws ErrorException editable_table(df, ["zzz"])

    @test create_dataframe(nothing) == DataFrame()
    @test create_dataframe(Dict(:a => 1, :b => 2)) == DataFrame(a=1, b=2)
    @test create_dataframe([Dict(:a => 1, :b => 2), Dict(:a => 3, :b => 4)]) == DataFrame(a=[1, 3], b=[2, 4])

end
