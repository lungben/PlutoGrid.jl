module PlutoGrid

using HypertextLiteral: @htl
using Tables
using DataFrames

export readonly_table

function make_col_defs(df; sortable=true, filterable=true)
    column_defs = Dict[]
	for c in names(df)
		
		col_dict = Dict("field" => c, "sortable" => sortable)
		
		if eltype(df[!, c]) <: Number
			col_dict["type"] = "numericColumn"
			filterable && (col_dict["filter"] = "agNumberColumnFilter")
		else
			col_dict["filter"] = filterable
		end
		push!(column_defs, col_dict)
	end
    return column_defs
end

prepare_data(df) = [NamedTuple(row) for row in Tables.rows(df)]

function readonly_table(df; sortable=true, filterable=true, pagination=false)
	column_defs = make_col_defs(df; sortable, filterable)
	data = prepare_data(df)
    return readonly_table(column_defs, data; pagination)
end

readonly_table(column_defs:: AbstractVector{<: AbstractDict}, data:: AbstractVector; pagination=false) = @htl("""
<html lang="en">
<head>
    <script src="https://unpkg.com/ag-grid-community/dist/ag-grid-community.min.js"></script>
<script>
const columnDefs = $(column_defs);

// specify the data
const rowData = $(data);

// let the grid know which columns and what data to use
const gridOptions = {
  columnDefs: columnDefs,
  rowData: rowData,
  pagination: $(pagination)
};

// setup the grid after the page has finished loading
document.addEventListener('DOMContentLoaded', () => {
    const gridDiv = document.querySelector('#myGrid');
    new agGrid.Grid(gridDiv, gridOptions);
});

</script>
</head>
<body>
    <div id="myGrid" class="ag-theme-alpine"></div>
</body>
</html>
""")

# precompilation
let
	df = DataFrame(x=1:10, y=10:-1:1)
	readonly_table(df)
end
	
end
