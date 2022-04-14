using Test



@testset "Vertices Congruence" begin
	err = 1e-7
	G = [
		0.0 err 0.0 0.0 0.0
		0.0 0.0 err 0.0 0.0
		0.0 0.0 0.0 err 0.0
	]
	G1, Vcls = CAGD.vcongruence(G[:, 1:4], epsilon=err)
	@test G1 == ([err; err; err]/4)[:,:];
	@test Vcls == [[1, 2, 3, 4]]
	G1, Vcls = CAGD.vcongruence(G[:, 2:5], epsilon=err)
	@test G1 == G[:, 2:4]/2;
	@test Vcls == [[1,4],[2,4],[3,4]];
end

@testset "Cell Congruence" begin

end

@testset "One Cube Fragmentation" begin
	G = [
		0.5310492999999998 1.0146684 0.3477716 0.8313907882395298 0.6061046999999998 1.0897237999999998 0.42282699999999984 0.9064461979373597 0.5310493 1.0146684000000001 0.6061047 1.0897237772434623 0.3477716 0.8313908 0.422827 0.9064462 0.5310493 0.34777160000000007 0.6061047 0.4228270000000002 1.0146684 0.8313908 1.0897238 0.9064461675456482;
		0.8659989999999999 0.6827212999999999 0.5268921 0.3436144447063971 1.2188832999999994 1.0356056999999999 0.8797763999999998 0.6964987903021808 0.8659989999999999 0.6827213 1.2188833 1.035605657895053 0.5268921 0.3436145 0.8797764000000001 0.6964988 0.8659989999999999 0.5268920999999999 1.2188833 0.8797764 0.6827213 0.3436145 1.0356057 0.6964988122992563;
		0.14191280000000003 0.2169682 0.4947971000000001 0.5698524407571428 0.5200012 0.5950565999999999 0.8728855 0.9479408896095312 0.14191279999999987 0.21696819999999994 0.5200011999999999 0.5950566438156151 0.4947971 0.5698525000000001 0.8728855 0.9479409 0.14191280000000006 0.4947971000000001 0.5200012000000002 0.8728855000000001 0.21696819999999994 0.5698525000000001 0.5950565999999999 0.9479408949632379
	];
	Delta_0 = SparseArrays.sparse((
		[1, 3, 1, 4, 2, 3, 2, 4, 5, 7, 5, 8, 6, 7, 6, 8, 9, 11, 9, 12, 10, 11, 10, 12, 13, 15, 13, 16, 14, 15, 14, 16, 17, 19, 17, 20, 18, 19, 18, 20, 21, 23, 21, 24, 22, 23, 22, 24],
		[1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19, 20, 20, 21, 21, 22, 22, 23, 23, 24, 24],
		Int8[-1, -1, 1, -1, -1, 1, 1, 1, -1, -1, 1, -1, -1, 1, 1, 1, -1, -1, 1, -1, -1, 1, 1, 1, -1, -1, 1, -1, -1, 1, 1, 1, -1, -1, 1, -1, -1, 1, 1, 1, -1, -1, 1, -1, -1, 1, 1, 1]
	)...);
	Delta_1 = SparseArrays.sparse((
		[1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6],
		[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24],
		Int8[1, -1, -1, 1, 1, -1, -1, 1, 1, -1, -1, 1, 1, -1, -1, 1, 1, -1, -1, 1, 1, -1, -1, 1]
	)...);

	V, EV, FE = CAGD.chaincongruence(G, Delta_0, Delta_1)

	@test V == [0.5310492999999998 1.0146684 0.3477716 0.8313907960798432 0.6061046999999999 1.0897237924144874 0.422827 0.906446188494336; 0.8659989999999999 0.6827212999999999 0.5268921 0.343614481568799 1.2188832999999997 1.0356056859650178 0.8797763999999999 0.6964988008671457; 0.14191279999999998 0.21696819999999994 0.49479710000000005 0.569852480252381 0.5200012 0.595056614605205 0.8728855000000001 0.9479408948575897]
	@test sort(EV) == [[1, 2], [1, 3], [1, 5], [2, 4], [2, 6], [3, 4], [3, 7], [4, 8], [5, 6], [5, 7], [6, 8], [7, 8]]
	@test sort(FE) == [[1, 2, 3, 4], [1, 5, 9, 10], [2, 6, 11, 12], [3, 7, 9, 11], [4, 8, 10, 12], [5, 6, 7, 8]]
end
