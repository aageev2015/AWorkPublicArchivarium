function comparationTest(OutputFunction, IsFull) {
	var arr = ['', 0, 1, '0', '1', null, NaN, undefined, 'a', 1.1, '1.1', false, true, 22, '22', 'true', 'false', 'True', 'False', 'TRUE', 'FALSE'];
	var captions = ['\'\'', '0', '1', '\'0\'', '\'1\'', 'null', 'NaN', 'undefined', '\'a\'', '1.1', '\'1.1\'', 'false', 'true', '22', '\'22\'', '\'true\'', '\'false\'', '\'True\'', '\'False\'', '\'TRUE\'', '\'FALSE\''];
	var cnt = arr.length;
	//var Results = [];
	//var Result;
	for(var i = 0; i<cnt; i++) {
		Result = [];
		for(var j = 0; j < cnt; j++) {
			if (!IsFull && (arr[i] == arr[j] || arr[i] === arr[j])) {
				Result.push(
					captions[j] + ' '
				+	((arr[i] == arr[j]) ? '+':'-') 
				+ 	'\\'
				+	((arr[i] === arr[j]) ? '+':'-')
				)
			}
		}
		OutputFunction(captions[i] + ': ' + Result.join(',  '));
		//Results.push(Result);
	}
}


//results
//int
	var OutFn = function(T) {Log.Write(1, T)};
	comparationTest(OutFn, true);
	OutFn('');
	comparationTest(OutFn, false);
//out
'': '' +\+,  0 +\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false +\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
0: '' +\-,  0 +\+,  1 -\-,  '0' +\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false +\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
1: '' -\-,  0 -\-,  1 +\+,  '0' -\-,  '1' +\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true +\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'0': '' -\-,  0 +\-,  1 -\-,  '0' +\+,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false +\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'1': '' -\-,  0 -\-,  1 +\-,  '0' -\-,  '1' +\+,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true +\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
null: '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null +\+,  NaN -\-,  undefined +\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
NaN: '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
undefined: '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null +\-,  NaN -\-,  undefined +\+,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'a': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' +\+,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
1.1: '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 +\+,  '1.1' +\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'1.1': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 +\-,  '1.1' +\+,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
false: '' +\-,  0 +\-,  1 -\-,  '0' +\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false +\+,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
true: '' -\-,  0 -\-,  1 +\-,  '0' -\-,  '1' +\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true +\+,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
22: '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 +\+,  '22' +\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'22': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 +\-,  '22' +\+,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'true': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' +\+,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'false': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' +\+,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'True': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' +\+,  'False' -\-,  'TRUE' -\-,  'FALSE' -\-
'False': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' +\+,  'TRUE' -\-,  'FALSE' -\-
'TRUE': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' +\+,  'FALSE' -\-
'FALSE': '' -\-,  0 -\-,  1 -\-,  '0' -\-,  '1' -\-,  null -\-,  NaN -\-,  undefined -\-,  'a' -\-,  1.1 -\-,  '1.1' -\-,  false -\-,  true -\-,  22 -\-,  '22' -\-,  'true' -\-,  'false' -\-,  'True' -\-,  'False' -\-,  'TRUE' -\-,  'FALSE' +\+

'': '' +\+,  0 +\-,  false +\-
0: '' +\-,  0 +\+,  '0' +\-,  false +\-
1: 1 +\+,  '1' +\-,  true +\-
'0': 0 +\-,  '0' +\+,  false +\-
'1': 1 +\-,  '1' +\+,  true +\-
null: null +\+,  undefined +\-
NaN: 
undefined: null +\-,  undefined +\+
'a': 'a' +\+
1.1: 1.1 +\+,  '1.1' +\-
'1.1': 1.1 +\-,  '1.1' +\+
false: '' +\-,  0 +\-,  '0' +\-,  false +\+
true: 1 +\-,  '1' +\-,  true +\+
22: 22 +\+,  '22' +\-
'22': 22 +\-,  '22' +\+
'true': 'true' +\+
'false': 'false' +\+
'True': 'True' +\+
'False': 'False' +\+
'TRUE': 'TRUE' +\+
'FALSE': 'FALSE' +\+