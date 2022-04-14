Lar = LinearAlgebraicRepresentation

using IntervalTrees
using SparseArrays
using NearestNeighbors
using DataStructures


#-------------------------------------------------------------------------------
#   MODEL BOUNDING BOXES
#-------------------------------------------------------------------------------

"""
	getModelBoundingBoxes(
		model::CAGD.Model,
		deg::Int,
		cells = 1 : size(model, deg, 1);
		atol = 1e-10
	)::Array{Array{Float64,2},1}

Evaluates the bounding boxes related to each `deg`-cell of the `model`

The function builds a vector of matrices containing the two distincive vertices
of the axis-coherent hyper-cube that contains each `deg`-cell.

If `cells` is specified, then only those bounding boxes are evaluated

Keyword parameter `atol` specifies the tollerance added to the bounding box

See also: [`CAGD.spatialIndex`](@ref)
It uses:
---
# Examples
```jldoctest
julia> model = CAGD.Model(hcat([
		[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.5, 1.0], [0.5, 1.0, 0.5], [1.0, 1.0, 0.5]
	]...));
julia> CAGD.addModelCells!(model, 1, [[1, 2], [2, 5], [3, 4], [4, 5]]);

julia> CAGD.getModelBoundingBoxes(model,1)
4-element Array{Array{Float64,2},1}:
4-element Array{Array{Float64,2},1}:
 [0.0 1.0; 0.0 1.0; 0.0 0.0]
 [0.0 1.0; 1.0 1.0; 0.0 0.5]
 [0.0 0.5; 0.5 1.0; 0.5 1.0]
 [0.5 1.0; 1.0 1.0; 0.5 0.5]
```
"""

function getModelBoundingBoxes(
		model::CAGD.Model,
		deg::Int,
		cells = 1 : size(model, deg, 1);
		atol = 1e-10
	)::Array{Array{Float64,2},1}

	function findBBox(pts::Lar.Points)::Tuple{Array{Float64,2},Array{Float64,2}}
		minimum = mapslices(x->min(x...), pts, dims=2) .- 2*atol
		maximum = mapslices(x->max(x...), pts, dims=2) .+ 2*atol
		return minimum, maximum
	end

	cellpts = [ hcat(CAGD.getModelCellVertices(model, deg, c)...)  for c in cells ]
	return [hcat(findBBox(c)...) for c in cellpts]
end

#-------------------------------------------------------------------------------
#   MODEL BOUNDING BOXES INCLUSION
#-------------------------------------------------------------------------------

"""
	isBoundingBoxIncluded(bbox1::Array{Float64,2}, bbox2::Array{Float64,2})::Bool

Checks whether `bbox1` is totally included in `bbox2`
"""
function isBoundingBoxIncluded(bbox1::Array{Float64,2}, bbox2::Array{Float64,2})::Bool
	dim = size(bbox1, 1)
	for d = 1 : dim
		(bbox1[d, 1] >= bbox2[d, 1]) & (bbox1[d, 2] <= bbox2[d, 2]) || return false
	end
	return true
end

#-------------------------------------------------------------------------------
#   SPATIAL_INDEXING METHODS
#	 buildBBIntervalTree
#	 extractBoxCovering
#-------------------------------------------------------------------------------

"""
	buildBBIntervalTree(
		bboxes::Array{Array{Float64,2},1},
		dim::Int
	)::IntervalTrees.IntervalMap{Float64, Array}

Build the Interval Tree of a set of bounding boxes along the `dim` coordinate.
"""
function buildBBIntervalTree(
		bboxes::Array{Array{Float64,2},1},
		dim::Int
	)::IntervalTrees.IntervalMap{Float64, Array}

	# Build the dictionary related to the `dim`-coordinate
	boxDict = OrderedDict{Array{Float64,1}, Array{Int,1}}()
	for (h, box) in enumerate(bboxes)
		key = box[dim, :]
		if haskey(boxDict, key) == false
			boxDict[key] = [h]
		else
			push!(boxDict[key], h)
		end
	end

	# Build the related Interval Tree
	iT = IntervalTrees.IntervalMap{Float64, Array}()
	for (key, boxSet) in boxDict
		iT[tuple(key...)] = boxSet
	end

	return iT
end

"""
	extractBoxCovering(
		bboxes::Array{Array{Float64,2},1},
		dim::Int
	)::Array{Array{Int,1},1}

Evaluates possible `bboxes` intersections over the `dim`-th coordinate

The function evaluates the pairwise intersection between the `dim` coordinate
of each `bboxes` couple. The operation is performed via Interval Tree.
"""
function extractBoxCovering(
		bboxes::Array{Array{Float64,2},1},
		dim::Int
	)::Array{Array{Int,1},1}

	# Build the related Interval Tree
	tree = CAGD.buildBBIntervalTree(bboxes, dim)

	# Build the covers
	covers = [[] for k = 1 : length(bboxes)]
	for (i, bbox) in enumerate(bboxes)
		extent = bboxes[i][dim, :]
		iterator = IntervalTrees.intersect(tree, tuple(extent...))
		for x in iterator
			append!(covers[i], x.value)
		end
	end

	return covers
end

#-------------------------------------------------------------------------------
#   SPATIAL_INDEXING
#-------------------------------------------------------------------------------

"""
	spaceIndex(model::CAGD.Model, dim::Int)::Array{Array{Int,1},1}

Generation of *space indexes* for all ``(d-1)``-dim cell members of `model`.

*Spatial index* made by ``d`` *interval-trees* on
bounding boxes of ``sigma in S_{d−1}``. Spatial queries solved by
intersection of ``d`` queries on IntervalTrees generated by
bounding-boxes of geometric objects (LAR cells).

The return value is an array of arrays of `int`s, indexing cells whose
containment boxes are intersecting the containment box of the first cell.
According to Hoffmann, Hopcroft, and Karasick (1989) the worst-case complexity of
Boolean ops on such complexes equates the total sum of such numbers.

# Examples 2D

```
julia> model = CAGD.Model(hcat([[0.,0],[1,0],[1,1],[0,1],[2,1]]...));

julia> CAGD.addModelCells!(model, 1, [[1,2],[2,3],[3,4],[4,1],[1,5]]);

julia> Sigma = CAGD.spaceIndex(model, 1)
5-element Array{Array{Int64,1},1}:
 [4, 5, 2]
 [1, 3, 5]
 [4, 5, 2]
 [1, 3, 5]
 [4, 1, 3, 2]
```

# Example 3D

```julia
julia> model = CAGD.Model([
		0.0 1.0 0.0 0.0 0.0 0.0 1.0
		0.0 0.0 1.0 0.0 0.0 0.0 0.0
		0.0 0.0 0.0 1.0 2.0 3.0 2.0
	])
julia> CAGD.addModelCells!(model, 1, [
		[1,3],[1,2],[2,3],[3,4],[2,4],[1,4],[4,5],[5,7],[6,7],[5,6]
	])
julia> CAGD.addModelCells!(model, 2,[
		[1,2,3],[1,4,6],[2,5,6],[3,4,5],[8,9,10]
	])

julia> CAGD.spaceIndex(model, 1)
10-element Array{Array{Int64,1},1}:
 [4, 6, 2, 3, 5]
 [1, 4, 6, 3, 5]
 [1, 4, 6, 2, 5]
 [1, 6, 7, 2, 3, 5]
 [1, 4, 6, 7, 2, 3]
 [1, 4, 7, 2, 3, 5]
 [4, 6, 10, 5, 8, 9]
 [7, 10, 9]
 [7, 10, 8]
 [7, 8, 9]

CAGD.spaceIndex(model, 2)
5-element Array{Array{Int64,1},1}:
 [2, 3, 4]
 [1, 3, 4]
 [2, 1, 4]
 [2, 1, 3]
 []

```
"""
function spaceIndex(model::CAGD.Model, dim::Int)::Array{Array{Int,1},1}

	bboxes = CAGD.getModelBoundingBoxes(model, dim)
	# Build Box Coverings for each dimension and intersecting them
	covers = CAGD.extractBoxCovering(bboxes, 1)
	for d = 2 : length(model)
		dcovers = CAGD.extractBoxCovering(bboxes, d)
		covers  = [intersect(pair...) for pair in zip(covers, dcovers)]
	end

	# Remove each cell from its cover
	for k = 1 : length(covers)
		covers[k] = setdiff(covers[k],[k])
	end

	return covers
end
