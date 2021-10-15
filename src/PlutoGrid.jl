module PlutoGrid

using HypertextLiteral: @htl, JavaScript
using Tables
using DataFrames

export readonly_table, editable_table, create_dataframe

const MODIFIED_COL_INDICATOR = "modified_column_"
const MODIFIED_COL_REGEX = r"^(?!modified_column_).+"

"""
	readonly_table(df; sortable=true, filterable=true, pagination=false)

Shows a non-editable table in Pluto.

`df`: DataFrame or any Tables.jl compatible data source (the latter is internally converted to a DataFrame)

`sortable`: enables sorting in the table GUI for all columns (enabled by default)

`filterable`: enables filtering in the table GUI for all columns (enabled by default)

`resizable`: allows resizing of column widths in GUI (enabled by default)

`pagination`: enables pagination of the table (disabled by default)

`height`: vertical size of the table in Pluto in pixel (default: 600)

"""
function readonly_table(df:: DataFrame; filterable:: Bool=true, kwargs...)
	column_defs = _make_col_defs(df; filterable)
	data = _prepare_data(df)
    return _create_table(column_defs, data; filterable, kwargs...)
end

readonly_table(df; kwargs...) = readonly_table(DataFrame(df); kwargs...)

"""
	@bind edits editable_table(df, [editable_cols]; sortable=true, filterable=true, pagination=false, height=600, return_only_modified=false)

Shows an editable table in Pluto. In case of user edits in the table, 

`df`: DataFrame or any Tables.jl compatible data source (the latter is internally converted to a DataFrame)

`editable_cols`: (optional) Names of columns which are editable. If not given, all columns are editable.

`sortable`: enables sorting in the table GUI for all columns (enabled by default)

`filterable`: enables filtering in the table GUI for all columns (enabled by default)

`resizable`: allows resizing of column widths in GUI (enabled by default)

`pagination`: enables pagination of the table (disabled by default)

`height`: vertical size of the table in Pluto in pixel (default: 600)

"""
function editable_table(df:: DataFrame, editable_cols:: AbstractVector{<: AbstractString}=collect(names(df)); filterable:: Bool=true, return_only_modified:: Bool=false, kwargs...)
	column_defs = _make_col_defs(df; filterable, editable_cols)
	data = _prepare_data(df)
	return _create_table(column_defs, data; editable=true, filterable, kwargs...)
end

editable_table(df, editable_cols; kwargs...) = editable_table(DataFrame(df), editable_cols; kwargs...)
editable_table(df; kwargs...) = editable_table(DataFrame(df); kwargs...)


function _create_table(column_defs:: AbstractVector{<: AbstractDict}, data:: AbstractVector; 
	sortable=true, filterable=true, resizable=true, pagination=false, height:: Integer=600,
	editable=false, insert=true, delete=true, auto_confirm=false)

	edit_button = @htl("""
		<button  
			id="update_grid"
			type="button">
				Confirm  
		</button>
	""")

	edit_button_callbacks = JavaScript("""
	div.querySelector("button#update_grid").addEventListener("click", (e) => {
		div.value = rowData; // return complete table
		div.dispatchEvent(new CustomEvent("input"));
		e.preventDefault();
		div.querySelector("button#update_grid").style.background='green';
		})
	""")

	insert_button = @htl("""
		<button  
		id="insert_row"
		type="button">
			Insert Row  
		</button>
	""")

	insert_new_row_callback = JavaScript("""
	div.querySelector("button#insert_row").addEventListener("click", (e) => {
		const row = Object.assign({}, rowData[rowData.length - 1]);
		gridOptions.rowData.push(row);
		gridOptions.api.setRowData(gridOptions.rowData);
		const data = gridOptions.rowData[gridOptions.rowData.length -1]
		gridOptions.columnApi.getAllColumns().forEach(col => {
			data[$(MODIFIED_COL_INDICATOR) + col.colId] = true;
			});

		gridOptions.api.refreshCells({force: true});

		div.querySelector("button#update_grid").style.background='red';
		})
	""")

	delete_button = @htl("""
		<button  
		id="delete_row"
		type="button">
			Delete Row  
		</button>
	""")

	delete_row_callback = JavaScript("""
	div.querySelector("button#delete_row").addEventListener("click", (e) => {

		const selectedRow = gridOptions.api.getFocusedCell()
		const id = gridOptions.rowData[selectedRow.rowIndex].i
		
		gridOptions.rowData.splice(selectedRow.rowIndex, 1)
		gridOptions.api.setRowData(gridOptions.rowData)

		div.querySelector("button#update_grid").style.background='red';
		})
	""")

	checkbox_renderer = JavaScript("""
	function CheckboxRenderer() {}

		CheckboxRenderer.prototype.init = function(params) {
		  this.params = params;
		
		  this.eGui = document.createElement('input');
		  this.eGui.type = 'checkbox';
		  this.eGui.checked = params.value;
		
		  this.checkedHandler = this.checkedHandler.bind(this);
		  this.eGui.addEventListener('click', this.checkedHandler);
		}
		
		CheckboxRenderer.prototype.checkedHandler = function(e) {
		  let checked = e.target.checked;
		  let colId = this.params.column.colId;
		  this.params.node.setDataValue(colId, checked);
		}
		
		CheckboxRenderer.prototype.getGui = function(params) {
		  return this.eGui;
		}
		
		CheckboxRenderer.prototype.destroy = function(params) {
		  this.eGui.removeEventListener('click', this.checkedHandler);
		}
	""")

	return @htl("""
<div id="myGrid" style="height: $(height)px;" class="ag-theme-alpine">
$(editable ? edit_button : "")
$((editable && insert) ? insert_button : "")
$((editable && delete) ? delete_button : "")

<script src="https://unpkg.com/ag-grid-community/dist/ag-grid-community.min.js"></script>
<script>

function numberParser(params) {
	return Number(params.newValue);
};

var div = currentScript.parentElement;
// set default output value
div.value = null;

const columnDefs = $(column_defs);
const rowData = $(_transfer_data(data));

$checkbox_renderer

$(editable ? edit_button_callbacks : JavaScript(""))
$((editable && insert) ? insert_new_row_callback : JavaScript(""))
$((editable && insert) ? delete_row_callback : JavaScript(""))

// let the grid know which columns and what data to use
const gridOptions = {
  columnDefs: columnDefs,
  rowData: rowData,
  components: { checkboxRenderer: CheckboxRenderer },
  defaultColDef: {
    filter: $(sortable),
    sortable: $(filterable),
	resizable: $(resizable),
	cellStyle: params => {
		// source: https://stackoverflow.com/questions/65273946/ag-grid-highlight-cell-logic-not-working-properly
      if (
        params.data[$(MODIFIED_COL_INDICATOR)+ params.column.colDef.field]
      ) {
        return { 'color': 'red', 'background-color': 'yellow' };
      } else {
        return null;
      }
    },
  },
  pagination: $(pagination),
  undoRedoCellEditing: true,
  onCellValueChanged: (params) => {
		if (params.oldValue === params.newValue) {
		return;
		}
		const column = params.column.colDef.field;
		params.data[$(MODIFIED_COL_INDICATOR) + column] = true;
		params.api.refreshCells({
		force: true,
		columns: [column],
		rowNodes: [params.node]
		});
		div.querySelector("button#update_grid").style.background='red';
	},
	onCellKeyPress: (event) => {
		if ((event.event.keyCode == 13) && (event.event.shiftKey == true)) {
			div.querySelector("button#update_grid").click();
		}
	},
};
new agGrid.Grid(div, gridOptions);

$(auto_confirm ? JavaScript("""div.querySelector("button#update_grid").click();""") : JavaScript(""))

</script>
</div>
""")
end

function _make_col_defs(df; filterable=true, editable_cols=String[])
	setdiff(editable_cols, names(df)) == [] || error("not all columns defined as editable are in input data")
    
	column_defs = Dict[]
	for c in names(df)
		col_dict = Dict{String, Any}("field" => c)

		col_is_editable = c ∈ editable_cols
		col_dict["editable"] = col_is_editable
		
		# special types and filters for specific element types
		if eltype(df[!, c]) <: Bool
			col_dict["cellRenderer"] = JavaScript("""'checkboxRenderer'""")

		elseif eltype(df[!, c]) <: Number
			col_dict["type"] = "numericColumn"
			filterable && (col_dict["filter"] = "agNumberColumnFilter")
			col_is_editable && (col_dict["valueParser"] = JavaScript("numberParser"))
		end
		# ToDo: add type / filter for dates

		push!(column_defs, col_dict)
	end
    return column_defs
end

_prepare_data(df) = [NamedTuple(row) for row in Tables.rows(df)]

_transfer_data(data) = if isdefined(Main, :PlutoRunner) && isdefined(Main.PlutoRunner, :publish_to_js)
	# faster data transfer using MsgPack
	JavaScript(Main.PlutoRunner.publish_to_js(data))
else
	data
end

"""
	create_dataframe(x)

Utility function to create a DataFrame from a `@bind` variable of a `editable_table`.
"""
create_dataframe(::Nothing; kwargs...) = DataFrame()
create_dataframe(::Missing; kwargs...) = DataFrame()

function create_dataframe(x:: Dict; drop_modified_indicator=true) 
	df = DataFrame(x)
	drop_modified_indicator ? df[:, MODIFIED_COL_REGEX] : df
end


function create_dataframe(x:: AbstractVector; drop_modified_indicator=true)
	df = DataFrame()
	for row in x
		push!(df, row; cols=:union)
	end
	drop_modified_indicator ? df[:, MODIFIED_COL_REGEX] : df
end

# precompilation
let
	df = DataFrame(x=1:10, y=10:-1:1)
	readonly_table(df)
	editable_table(df)
end
	
end
