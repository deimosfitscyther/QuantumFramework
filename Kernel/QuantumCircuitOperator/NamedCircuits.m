(* ::Package:: *)

Package["Wolfram`QuantumFramework`"]
PackageImport["Wolfram`QuantumFramework`QuantumOptimization`"]
PackageScope["$QuantumCircuitOperatorNames"]



$QuantumCircuitOperatorNames = {
	"ControlledMultiplexer",
    "Graph", "GHZ",
    "GroverDiffusion", "GroverDiffusion0",
    "GroverPhaseDiffusion", "GroverPhaseDiffusion0",
    "BooleanOracle", "PhaseOracle", "GrayOracle",
    "DeutschJozsaPhaseOracle", "DeutschJozsaBooleanOracle", "DeutschJozsaPhase", "DeutschJozsa", "DeutschPhase", "Deutsch",
    "SimonOracle", "Simon",
    "BooleanOracleR",
    "Grover", "GroverPhase",
    "Grover0", "GroverPhase0",
    "Bell", "Toffoli", "Fredkin",
    "BernsteinVaziraniOracle", "BernsteinVazirani",
    "Fourier", "InverseFourier",
    "PhaseEstimation",
    "Number", "PhaseNumber",
    "Controlled", "Switch",
    "Trotterization",
    "Magic",
    "Multiplexer", "ControlledMultiplexer",
    "QuantumState",
    "CHSH", "LeggettGarg", "WignerCHSH"
}


QuantumCircuitOperator[{"Graph", HoldPattern[g_Graph : RandomGraph[{5, 8}]], m : _Integer ? NonNegative : 0, gate_ : {"C", "1"}}, opts___] := With[{
    ig = If[AllTrue[VertexList[g], Internal`PositiveIntegerQ], g, IndexGraph @ g]
},
    QuantumCircuitOperator[
        Join["H" -> # & /@ Range[Max[VertexList[ig]]], QuantumOperator[gate, {#1, #2} + m] & @@@
            EdgeList[ig]], "Label" -> "\[ScriptCapitalG]", opts
    ]
]


QuantumCircuitOperator[{"GHZ", n : _Integer ? Positive : 3}, opts___] :=
    QuantumCircuitOperator[{"H", Splice["CNOT" -> # & /@ Partition[Range[n], 2, 1]]}, "Label" -> "GHZ", opts]


QuantumCircuitOperator[{"GroverAmplification" | "GroverDiffusion",
    xs : {_Integer ? Positive..},
    gate : _ ? QuantumOperatorQ | Automatic : Automatic
}, opts___] := Module[{
    op = If[gate === Automatic, QuantumOperator["NOT", {Max[xs]}], QuantumOperator[gate]], ys
},
    ys = DeleteCases[xs, Alternatives @@ op["OutputOrder"]];
    QuantumCircuitOperator[{
        Splice[Table[QuantumOperator["H", {q}], {q, ys}]],
        Splice[Table[QuantumOperator["X", {q}], {q, ys}]],
        QuantumOperator[{"Controlled", op, ys}],
        Splice[Table[QuantumOperator["X", {q}], {q, ys}]],
        Splice[Table[QuantumOperator["H", {q}], {q, ys}]]
    },
        opts,
        "Label" -> "Grover Amplification"
    ]
]

QuantumCircuitOperator[{"GroverPhaseAmplification" | "GroverPhaseDiffusion",
    xs : {_Integer ? Positive..},
    gate : _ ? QuantumOperatorQ | Automatic : Automatic
}, opts___] := With[{
    op = If[gate === Automatic, QuantumOperator["1", {Max[xs]}], QuantumOperator[gate]]
},
    QuantumCircuitOperator[{
        Splice[Table[QuantumOperator["H", {q}], {q, xs}]],
        Splice[Table[QuantumOperator["X", {q}], {q, xs}]],
        QuantumOperator[{"Controlled", op, DeleteElements[xs, op["OutputOrder"]]}],
        Splice[Table[QuantumOperator["X", {q}], {q, xs}]],
        Splice[Table[QuantumOperator["H", {q}], {q, xs}]]
    },
        opts,
        "Label" -> "Grover Diffusion"
    ]
]

QuantumCircuitOperator[{"GroverAmplification0" | "GroverDiffusion0",
    xs : {_Integer ? Positive..},
    gate : _ ? QuantumOperatorQ | Automatic : Automatic
}, opts___] := Block[{
    op = If[gate === Automatic, QuantumOperator["NOT", {Max[xs]}], QuantumOperator[gate]], ys
},
    ys = DeleteCases[xs, Alternatives @@ op["OutputOrder"]];
    QuantumCircuitOperator[
        {
            Splice[Table[QuantumOperator["H", {q}], {q, ys}]],
            QuantumOperator[{"Controlled0", op, ys}],
            Splice[Table[QuantumOperator["H", {q}], {q, ys}]]
        },
        opts,
        "Label" -> "Grover Diffusion"
    ]
]

QuantumCircuitOperator[{"GroverPhaseAmplification0" | "GroverPhaseDiffusion0",
    xs : {_Integer ? Positive..},
    gate : _ ? QuantumOperatorQ | Automatic : Automatic
}, opts___] := With[{
    op = If[gate === Automatic, QuantumOperator["1", {Max[xs]}], QuantumOperator[gate]]
},
    QuantumCircuitOperator[
        {
            Splice[Table[QuantumOperator["H", {q}], {q, xs}]],
            QuantumOperator[{"Controlled0", If[op["Label"] === "1", QuantumOperator["0", op["Order"]], - op], DeleteElements[xs, op["OutputOrder"]]}],
            Splice[Table[QuantumOperator["H", {q}], {q, xs}]]
        },
        opts,
        "Label" -> "Grover Diffusion"
    ]
]

QuantumCircuitOperator[{
    name : "GroverAmplification" | "GroverAmplification0" | "GroverDiffusion" | "GroverDiffusion0" |
    "GroverPhaseAmplification" | "GroverPhaseDiffusion" | "GroverPhaseAmplification0" | "GroverPhaseDiffusion0",
    n : _Integer ? Positive : 3, gate_ : Automatic}, opts___] :=
    QuantumCircuitOperator[{name, Range[n], gate}, opts]


QuantumCircuitOperator[{
        name : "GroverOperator" | "Grover" | "GroverOperator0" | "Grover0" |
        "GroverPhaseOperator" | "GroverPhase" | "GroverPhaseOperator0" | "GroverPhase0",
        op_ ? QuantumFrameworkOperatorQ,
        gate_ : Automatic
    },
    opts___
] := QuantumCircuitOperator[
    QuantumCircuitOperator[{
        "Grover" <> If[StringContainsQ[name, "Phase"], "Phase", ""] <> "Diffusion" <> If[StringEndsQ[name, "0"], "0", ""],
        op["OutputOrder"],
        gate
    }
    ] @ op,
    opts
]


QuantumCircuitOperator[{
        name : "GroverOperator" | "Grover" | "GroverOperator0" | "Grover0" |
        "GroverPhaseOperator" | "GroverPhase" | "GroverPhaseOperator0" | "GroverPhase0",
        formula_ : BooleanFunction[2 ^ 6, 3],
        varSpec : _List | _Association | Automatic : Automatic,
        m : _Integer | Automatic | None : Automatic,
        gate_ : Automatic
    },
    opts___
] := Enclose @ Module[{
    oracle = Confirm @ QuantumCircuitOperator[{If[StringContainsQ[name, "Phase"], "PhaseOracle", "BooleanOracle"], formula, varSpec, If[StringContainsQ[name, "Phase"], Nothing, m]}], n
},
    n = Replace[m, Automatic :> Last @ oracle["OutputOrder"]];
    QuantumCircuitOperator[{
        name,
        oracle,
        QuantumOperator[Replace[gate, Automatic :> QuantumOperator[If[StringContainsQ[name, "Phase"], "1", "NOT"], {n}]], {n}]
    }, opts]
]

indicesPattern = {KeyValuePattern[0 | 1 -> {_Integer ? Positive...}]..}

BooleanExpression[formula_, vars_List] := Block[{
    esop = formula /. And -> List
},
    If[ MatchQ[esop, _Function],
        esop = esop @@ vars
    ];
    esop = Replace[esop, clause : Except[_Xor] :> {clause}]  /. Xor -> List;
    esop = Replace[esop, clause : Except[_List] :> {clause}, {1}];
    esop
]

BooleanIndices[formula_, vars : _List] := Enclose @ Module[{
    esop = BooleanExpression[formula, vars],
    indices
},
	indices = <|0 -> {}, 1 -> {}, KeySelect[Not @* MissingQ] @ PositionIndex @ Lookup[#, vars]|> & /@ Map[If[MatchQ[#, _Not], #[[1]] -> 0, # -> 1] &, esop, {2}];
	indices = SortBy[indices, Values /* Catenate /* Length];
    indices
]

OrderBooleanVariables[formula_, varSpec : _List | _Association | Automatic : Automatic] := Enclose @ Block[{vars, order},
    vars = Replace[varSpec, {
        Automatic | {__Integer} :> Replace[BooleanVariables[formula], k_Integer :> Array[\[FormalX], k]],
        rules : KeyValuePattern[{_ -> _Integer ? Positive}] :> DeleteDuplicates[Join[Replace[BooleanVariables[formula], k_Integer :> Array[\[FormalX], k]], Keys[rules]]]
    }];
    order = Replace[varSpec, {
        rules : KeyValuePattern[{_ -> _Integer ? Positive}] :>
            With[{freeOrder = Complement[Range[Max[Values[rules], Length[vars]]], Values[rules]], freeVars = Complement[vars, Keys[rules]]},
                Lookup[Join[rules, Thread[freeVars -> Take[freeOrder, Length[freeVars]]]], vars]
            ],
        Except[{__Integer}] :> Range[Length[vars]]
    }];
    ConfirmAssert[orderQ[order]];
    {vars, order}
]

QuantumCircuitOperator[{"BooleanOracle",
    formula_ : BooleanFunction[2 ^ 6, 3],
    varSpec : _List | _Association | Automatic : Automatic,
    n : _Integer | Automatic : Automatic,
    gate_ : "NOT"
}, opts___] := Enclose @ Block[{
    esopFormula, esop, vars, order, indices, negIndices, isNegative = False, targetQubit
},
    esopFormula = BooleanConvert[formula, "ESOP"];
    {vars, order} = Confirm @ OrderBooleanVariables[formula, varSpec];
    If[ MemberQ[order, n],
        targetQubit = n;
        order = If[# >= n, # + 1, #] & /@ order,
        targetQubit = Replace[n, Automatic -> Max[order] + 1]
    ];
    esop = BooleanExpression[esopFormula, vars];
    indices = ConfirmMatch[BooleanIndices[esopFormula, vars], indicesPattern];
    negIndices = ConfirmMatch[BooleanIndices[BooleanConvert[Not[Replace[formula, bf_BooleanFunction :> bf @@ vars]], "ESOP"], vars], indicesPattern];
    If[ Length[negIndices] < Length[indices],
        indices = negIndices;
        isNegative = True;
    ];
    indices = With[{repl = Thread[Range[Length[order]] -> order]}, Replace[indices, repl, {3}]];
    
    QuantumCircuitOperator[
        Join[
            Prepend[
                If[ #[1] === {} && #[0] === {},
                    QuantumOperator[If[esop === {{True}}, "NOT", "I"], {targetQubit}],
                    QuantumOperator[{"Controlled", QuantumOperator[gate, {targetQubit}], #[1], #[0]}]
                ] & /@ indices,
                If[isNegative, QuantumOperator[gate, {targetQubit}]["Dagger"], Nothing]
            ],
            QuantumOperator["I", {#}] & /@ Complement[Range[Max[indices, Length[vars]]], Append[Flatten @ Values[indices], targetQubit]]
        ],
        opts,
        "Label" -> If[MatchQ[formula, _BooleanFunction], esop, formula]
    ]
]

QuantumCircuitOperator[{"BooleanOracleR",
    formula_ : BooleanFunction[2 ^ 6, 3],
    varSpec : _List | _Association | Automatic : Automatic,
    n : _Integer ? NonNegative | Automatic : Automatic,
    rotationGate : {"RX" | "RY" | "RZ", _ ? NumericQ} : {"RZ", Pi}
}, opts___] := Enclose @ Block[{
    esopFormula, esop, vars, order, indices, negIndices, isNegative = False, l, angles, targetQubit
},
    esopFormula = BooleanConvert[formula, "ESOP"];
    {vars, order} = Confirm @ OrderBooleanVariables[formula, varSpec];
    If[ MemberQ[order, n],
        targetQubit = n;
        order = If[# >= n, # + 1, #] & /@ order,
        targetQubit = Replace[n, Automatic -> Max[order] + 1]
    ];
    esop = BooleanExpression[esopFormula, vars];
    indices = ConfirmMatch[BooleanIndices[esopFormula, vars], indicesPattern];
    negIndices = ConfirmMatch[BooleanIndices[BooleanConvert[Not[Replace[formula, bf_BooleanFunction :> bf @@ vars]], "ESOP"], vars], indicesPattern];
    If[ Length[negIndices] < Length[indices],
        indices = negIndices;
        isNegative = True;
    ];
    l = Length[order];
    angles = ConfirmMatch[BooleanGrayAngles[indices, rotationGate[[2]]], {{Repeated[{_, _Integer | {}}, 2 ^ l]} ..}];
    With[{repl = Thread[Range[Length[order]] -> order]},
        indices = Replace[indices, repl, {3}];
        angles = MapAt[Replace[repl], angles, {All, All, 2}]
    ];
	QuantumCircuitOperator[
        Join[
            Prepend[
                Flatten @ Map[{
                        If[#[[1]] == 0, Nothing, QuantumOperator[{rotationGate[[1]], #[[1]]}, {targetQubit}]],
                        If[#[[2]] === {}, QuantumOperator[If[esop === {{True}}, "NOT", "I"], {targetQubit}], QuantumOperator["CNOT", {#[[2]], targetQubit}]]
                    } &,
                    angles,
                    {2}
                ],
                If[isNegative, QuantumOperator[MapAt[Minus, rotationGate, {2}], {targetQubit}], Nothing]
            ],
            QuantumOperator["I", {#}] & /@ Complement[Range[Max[indices, Length[vars]]], Join[Flatten @ Values[indices], {targetQubit}]]
        ],
        opts,
        "Label" -> If[MatchQ[formula, _BooleanFunction], esop, formula]
    ]
]

QuantumCircuitOperator[{"GrayOracle",
    fangles : _Function | _List : {0},
    prec : _Integer ? Positive : 4,
    n : _Integer ? NonNegative | Automatic : Automatic,
    rotationGate : "RX" | "RY" | "RZ" : "RY"
}, opts___] := Enclose @ Block[{
    order, angles, targetQubit
},
    angles = PadRight[Replace[fangles, f_Function :> (1 / 2 ^ prec f[FromDigits[#, 2]] & /@ Tuples[{0, 1}, prec])], 2 ^ prec];
    order = Range[prec];
    If[ MemberQ[order, n],
        targetQubit = n;
        order = If[# >= n, # + 1, #] & /@ order,
        targetQubit = Replace[n, Automatic -> Max[order] + 1]
    ];
    targetQubit = If[MemberQ[order, n], First[DeleteCases[Range @@ ({0, 1} + MinMax[order]), n]], Replace[n, Automatic -> Max[order] + 1]];
    angles = Thread[{1 / 2 ^ prec Transpose[GrayMatrix[prec]] . angles, Extract[order, GrayOrders[prec]]}];
	QuantumCircuitOperator[
        Splice @ {
            QuantumOperator[{rotationGate, #1}, {targetQubit}],
            QuantumOperator["CNOT", {#2, targetQubit}]
        } & @@@ angles,
        opts,
        "Label" -> "GrayOracle"
    ]
]

GrayMatrix[n_] := With[{range = Range[0, 2 ^ n - 1]}, Outer[(-1)^Dot[##] &, IntegerDigits[range, 2, n], PadLeft[#, n] & /@ ResourceFunction["GrayCode"][range], 1]]

GrayOrders[n_] := SymmetricDifference @@@ Partition[Append[ResourceFunction["GrayCodeSubsets"][Range[n]], {}], 2, 1]

BooleanGrayAngles[indices : indicesPattern, angle_ : Pi] := KeyValueMap[
	With[{n = Length[#1], order = #1},
		Thread[{
            1 / 2 ^ n Transpose[GrayMatrix[n]] . ReplacePart[
                ConstantArray[0, 2 ^ n],
                Thread[Fold[BitSet, 0, n - Lookup[PositionIndex[order], #[1]]] + 1 & /@ #2 -> angle]
            ],
            Extract[order, GrayOrders[n]]
        }]
	] &,
    GroupBy[indices, Apply[Union]]
]

QuantumCircuitOperator[{"PhaseOracle",
    formula_ : BooleanFunction[2 ^ 6, 3],
    varSpec : _List | _Association | Automatic : Automatic,
    m : _Integer ? NonNegative : 0
}, opts___] := Enclose @ Block[{
    esopFormula = Confirm @ BooleanConvert[formula, "ESOP"], esop, vars, order, indices
},
    {vars, order} = Confirm @ OrderBooleanVariables[formula, varSpec];
    order = order + m;
    esop = BooleanExpression[esopFormula, vars];
	indices = m + <|0 -> {}, 1 -> {}, KeySelect[Not @* MissingQ] @ PositionIndex @ Lookup[#, vars]|> & /@ Map[If[MatchQ[#, _Not], #[[1]] -> 0, # -> 1] &, esop, {2}];
    indices = With[{repl = Thread[Range[Length[order]] -> order]}, Replace[indices, repl, {3}]];
    QuantumCircuitOperator[
        Join[
            If[ #[1] === {},
                If[ #[0] === {},
                    If[esop === {{True}}, Nothing, QuantumOperator[{"GlobalPhase", Pi}]],
                    QuantumOperator[{"Controlled0", "0", Most[#[0]]}, {Last[#[0]]}]
                ],
                QuantumOperator[{"Controlled", "1", Most[#[1]], #[0]}, {Last[#[1]]}]
            ] & /@ indices,
            QuantumOperator["I", {#}] & /@ Complement[Range[Max[indices, Length[vars]]], Flatten @ Values[indices]]
        ],
        opts,
        "Label" -> If[MatchQ[formula, _BooleanFunction], esop, formula]
    ]
]

QuantumCircuitOperator[{"PhaseOracle", formula_ : BooleanFunction[2 ^ 6, 3], vars : KeyValuePattern[_ -> _Integer ? Positive], n : _Integer ? NonNegative : 0}, opts___] :=
    QuantumCircuitOperator[{"PhaseOracle", formula, Lookup[Reverse /@ Normal @ vars, Range[Max[vars]]]}, opts]


QuantumCircuitOperator[{name : "DeutschJozsaPhaseOracle" | "DeutschJozsaBooleanOracle", f_ : 1, n : _Integer ? Positive | Automatic : Automatic}, opts___] :=
    With[{formula = Replace[f, i_Integer :> With[{m = Replace[n, Automatic :> Max[Ceiling[Log2[Log2[i]]], 1]]}, BooleanFunction[Mod[i - 1, 2 ^ 2 ^ m], m]]]},
        QuantumCircuitOperator[{StringReplace[name, "DeutschJozsa" -> ""], formula}, opts]
    ]

QuantumCircuitOperator[{"DeutschJozsaPhase", f_ : Automatic, n : _Integer ? Positive | Automatic : Automatic}, opts___] := Enclose @ With[{
    oracle = Confirm @ Replace[f, {
        Automatic :> 
            With[{m = Replace[n, Automatic -> 1]}, QuantumCircuitOperator[{QuantumCircuitOperator[{QuantumCircuitOperator[{"DeutschJozsaPhaseOracle", RandomInteger[{1, 2 ^ 2 ^ m}], m}]}, "?"]}, "Oracle"]],
        _ :> QuantumCircuitOperator[{"DeutschJozsaPhaseOracle", f, n}]
    }]
},
{
    m = oracle["Width"]
},
    QuantumCircuitOperator[
        {
            Splice["+" -> # & /@ Range[m]],
            oracle,
            Splice[QuantumMeasurementOperator["X", {#}] & /@ Range[m]]
        },
        opts,
        "Label" -> "Deutsch-Jozsa"
    ]
]

QuantumCircuitOperator[{"DeutschJozsa", f_ : Automatic, n : _Integer ? Positive | Automatic : Automatic}, opts___] := With[{
    oracle = Replace[f, {
        Automatic :> 
            With[{m = Replace[n, Automatic -> 1]}, QuantumCircuitOperator[{QuantumCircuitOperator[{QuantumCircuitOperator[{"DeutschJozsaBooleanOracle", RandomInteger[{1, 2 ^ 2 ^ m}], m}]}, "?"]}, "Oracle"]],
        _ :> QuantumCircuitOperator[{"DeutschJozsaBooleanOracle", f, n}]
    }]
},
{
    m = oracle["Width"] - 1
},
    QuantumCircuitOperator[{
            Splice["+" -> # & /@ Range[m]],
            "-" -> m + 1,
            oracle,
            Splice[QuantumMeasurementOperator["X", {#}] & /@ Range[m]]
        },
        opts,
        "Label" -> "Deutsch-Jozsa"
    ]
]

QuantumCircuitOperator[{"DeutschPhase", f_ : Automatic}, opts___] := QuantumCircuitOperator[{"DeutschJozsaPhase", f, 1}, opts]

QuantumCircuitOperator[{"Deutsch", f_ : Automatic}, opts___] := QuantumCircuitOperator[{"DeutschJozsa", f, 1}, opts, "Label" -> "Deutsch"]

QuantumCircuitOperator[name : "DeutschJozsaPhaseOracle" | "DeutschJozsaBooleanOracle" | "DeutschJozsaPhase" | "DeutschJozsa" | "DeutschPhase" | "Deutsch", opts___] := QuantumCircuitOperator[{name}, opts]


MinNumberOfArguments[f_Function] := Max[Cases[f, Verbatim[Slot][i_] :> i, All]]

QuantumCircuitOperator[{"SimonOracle", f : Verbatim[Function][output : {_BooleanFunction[___] ..}]}, opts___] := Enclose @ With[{n = MinNumberOfArguments[f]},
    ConfirmAssert[Length[output] == n, "Boolean function output should be the same size as input."];
    QuantumCircuitOperator[
        "Multiplexer" @@ QuantumTensorProduct @* Replace[{} -> QuantumOperator["I" -> n + 1]] @* MapIndexed[If[#1, Nothing, QuantumOperator["NOT", #2 + n]] &] /@ f @@@ Tuples[{0, 1}, n],
        opts,
        "Label" -> "Simon Oracle"
    ]

]

QuantumCircuitOperator[{"Simon", f : Verbatim[Function][{_BooleanFunction[___] ..}]}, opts___] := Enclose @ With[{n = MinNumberOfArguments[f]},
    QuantumCircuitOperator[{
        Splice["H" -> # & /@ Range[n]],
        Confirm @ QuantumCircuitOperator[{"SimonOracle", f}, ClickToCopy["Simon Oracle", f]],
        Splice["H" -> # & /@ Range[n]],
        Splice[List /@ Range[n]]
    }, opts, "Label" -> "Simon"]
]

QuantumCircuitOperator[{name : "SimonOracle" | "Simon", secret : {(0 | 1) ..} | Automatic : Automatic}, opts___] := Block[{
    s = Replace[secret, Automatic | {0 ..} :> RandomInteger[{0, 1}, Replace[secret, {s_List :> Length[s], _ -> 3}]]], n, x, fx, bf
},
    n = Length[s];
    x = RandomSample[Tuples[{0, 1}, n], 2 ^ (n - 1)];
    fx = RandomInteger[{0, 1}, {2 ^ (n - 1), n}];
    QuantumCircuitOperator[{name, BooleanFunction[Catenate @ MapThread[{#1 -> #2, BitXor[#1, s] -> #2} &, {x, fx}]]}, opts]
]

QuantumCircuitOperator[{name : "SimonOracle" | "Simon", s : {(False | True) ..}}, opts___] := QuantumCircuitOperator[{name, Boole[s]}, opts]

QuantumCircuitOperator[{name : "SimonOracle" | "Simon", s_String}, opts___] /; StringMatchQ[s, ("0" | "1") ..] := QuantumCircuitOperator[{name, IntegerDigits[FromDigits[s, 2], 2, StringLength[s]]}, opts]

QuantumCircuitOperator[(name : "SimonOracle" | "Simon") | {name : "SimonOracle" | "Simon"}, opts___] := QuantumCircuitOperator[{name, Automatic}, opts]


QuantumCircuitOperator[name : "Bell" | "Toffoli" | "Fredkin", opts___] := QuantumCircuitOperator[{name}, opts]

QuantumCircuitOperator[{"Bell", n : _Integer : 0}, opts___]  :=
    QuantumCircuitOperator[{"H", "CNOT"}, opts, "Label" -> "Bell"]["Shift", n]

QuantumCircuitOperator[{"Toffoli", n : _Integer : 0}, opts___] := QuantumCircuitOperator[
    {
        "H" -> 3, "CNOT" -> {2, 3}, SuperDagger["T"] -> 3, "CNOT" -> {1, 3}, "T" -> 3, "CNOT" -> {2, 3}, SuperDagger["T"] -> 3, "CNOT" -> {1, 3},
        "T" -> 2, "T" -> 3, "H" -> 3, "CNOT" -> {1, 2},  "T" -> 1, SuperDagger["T"] -> 2, "CNOT" -> {1, 2}
    },
    opts,
    "Label" -> "Toffoli"
]["Shift", n]

QuantumCircuitOperator[{"Fredkin", n : _Integer : 0}, opts___] := QuantumCircuitOperator[{
        "CNOT" -> {3, 2}, "H" -> 3, "T" -> 1, "T" -> 2, "T" -> 3, "CNOT" -> {2, 1}, "CNOT" -> {3, 2}, "CNOT" -> {1, 3}, SuperDagger["T"] -> 2, "CNOT" -> {1, 2},
        SuperDagger["T"] -> 1, SuperDagger["T"] -> 2, "T" -> 3, "CNOT" -> {3, 2}, "CNOT" -> {1, 3}, "H" -> 3, "CNOT" -> {2, 1}, "CNOT" -> {3, 2}
    },
    opts,
    "Label" -> "Fredkin"
]["Shift", n]

QuantumCircuitOperator[{"Switch", a_QuantumOperator : QuantumOperator["RandomUnitary"], b_QuantumOperator : QuantumOperator["RandomUnitary"]}, opts___] /;
    a["InputDimension"] == a["OutputDimension"] == b["InputDimension"] == b["OutputDimension"] := With[{d = a["InputDimension"]},
        QuantumCircuitOperator[{"Cup"[d] -> {3, 4}, "C0SWAP"[d], a -> 2, b -> 3, "CSWAP"[d], "Cap"[d] -> {3, 4}}, opts, "Label" -> "Switch"]
    ]

QuantumCircuitOperator[{"BernsteinVaziraniOracle", secret : {(0 | 1) ...} : {1, 0, 1}, m : _Integer ? NonNegative : 0}, opts___] := With[{n = Length[secret]},
    QuantumCircuitOperator[
        If[MatchQ[secret, {0 ...}], Append[QuantumOperator["I", {n + 1 + m}]], Identity] @
            MapIndexed[If[#1 === 1, QuantumOperator["CNOT", {First[#2], n + 1} + m], QuantumOperator["I", #2 + m]] & , secret],
        opts,
        "Label" -> "BV Oracle"
    ]
]

QuantumCircuitOperator[{"BernsteinVaziraniOracle", secret_String : "101", m : _Integer ? NonNegative : 0} /; StringMatchQ[secret, ("0" | "1") ...], opts___] :=
    QuantumCircuitOperator[{"BernsteinVaziraniOracle", Characters[secret] /. {"0" -> 0, "1" -> 1}, m}, opts]

QuantumCircuitOperator[{"BernsteinVazirani", secret : {(0 | 1) ...} | (secret_String /; StringMatchQ[secret, ("0" | "1") ...]) : "101", m : _Integer ? NonNegative : 0}, opts___] := With[{
    n = If[ListQ[secret], Length[secret], StringLength[secret]]
},
    QuantumCircuitOperator[{
        Splice @ Table[QuantumOperator["H", {i + m}], {i, n + 1}],
        QuantumOperator["Z", {n + 1 + m}],
        QuantumCircuitOperator[{"BernsteinVaziraniOracle", secret, m}],
        Splice @ Table[QuantumOperator["H", {i + m}], {i, n}],
        Splice @ Table[QuantumMeasurementOperator[{i + m}], {i, n}]
    },
        opts,
        "Label" -> "Bernstein-Vazirani"
    ]
]


QuantumCircuitOperator[{"Number",  n : _Integer ? NonNegative : 0, qubits : _Integer | Automatic : Automatic}, opts___] := Block[{
    qs = Replace[qubits, Automatic :> Ceiling[Max[Log2[n], 0]]], bits
},
    bits = IntegerDigits[n, 2, qs];
    QuantumCircuitOperator[MapIndexed[If[#1 == 1, "X", "I"] -> #2 &, bits], opts, "Label" -> n]
]

QuantumCircuitOperator[{"PhaseNumber", n : _Integer ? NonNegative : 0, qubits : _Integer | Automatic : Automatic, h : True | False : True}, opts___] := Block[{
    qs = Replace[qubits, Automatic :> Ceiling[Max[Log2[n], 0]]], bits
},
    bits = IntegerDigits[n, 2, qs];
	QuantumCircuitOperator[
        Join[
            If[h, Thread["H" -> Range[qs]], {}],
            Catenate @ Table[Map["PhaseShift"[#] -> q &, Catenate @ Position[bits[[- q ;;]], 1, {1}, Heads -> False]], {q, qs}]
        ],
        opts,
        "Label" -> n
    ]
]

QuantumCircuitOperator[name : "Fourier" | "InverseFourier", opts___] := QuantumCircuitOperator[{name, 2}, opts]

QuantumCircuitOperator[{"Fourier", n_Integer ? Positive, m : _Integer ? NonNegative : 0}, opts___] := QuantumCircuitOperator[Join[
		Catenate @ Table[{
			QuantumOperator["H", {i + m}],
			Splice[QuantumOperator[{"Controlled", {"PhaseShift", # + 1}, {# + i + m}}, {i + m}] & /@ Range[n - i]]
		},
		{i, n}],
		QuantumOperator["SWAP", {# + m, n - # + 1 + m}] & /@ Range[Floor[n / 2]]
	],
    opts,
	"Label" -> "QFT"
]

QuantumCircuitOperator[{"InverseFourier", n_Integer ? Positive, m : _Integer ? NonNegative : 0}, opts___] := QuantumCircuitOperator[{"Fourier", n, m}, opts]["Dagger"]


QuantumCircuitOperator[{
    "PhaseEstimation",
    (op : _ ? QuantumOperatorQ : QuantumOperator["RandomUnitary"]),
    n : _Integer ? Positive : 4,
    m : _Integer ? NonNegative : 0,
    params : OptionsPattern[{"PowerExpand" -> False}]
} /; op["InputDimensions"] === op["OutputDimensions"] && MatchQ[op["OutputDimensions"], {2 ..}] , opts___] :=
QuantumCircuitOperator[{
    Splice @ Table[QuantumOperator["X", {n + i + m}], {i, op["InputQudits"]}],
    Splice @ Table[QuantumOperator["H", {i + m}], {i, n}],
    With[{qo = QuantumOperator[op, op["QuditOrder"] + n + m]},
        If[ TrueQ[Lookup[{params}, "PowerExpand"]],
            Splice @ Catenate @ Table[Table[QuantumOperator[{"Controlled", qo, {i + m}}], 2 ^ (n - i)], {i, n}],
            Splice @ Table[QuantumOperator[{"Controlled", qo ^ 2 ^ (n - i), {i + m}}], {i, n}]
        ]
    ],
    QuantumCircuitOperator[{"InverseFourier", n}],
    Splice @ Table[QuantumMeasurementOperator[{i + m}], {i, n}]
},
    opts,
    "Label" -> "Phase Estimation"
]

QuantumCircuitOperator[{
    "PhaseEstimation",
    op_ ? QuantumCircuitOperatorQ /; op["InputDimensions"] === op["OutputDimensions"] && MatchQ[op["OutputDimensions"], {2 ..}],
    n : _Integer ? Positive : 4,
    m : _Integer ? NonNegative : 0
}, opts___] :=
QuantumCircuitOperator[{
    Splice @ Table[QuantumOperator["X", {n + i + m}], {i, op["InputQudits"]}],
    Splice @ Table[QuantumOperator["H", {i + m}], {i, n}],
    With[{qo = op["Shift", m]},
        Splice @ Catenate @ Table[Table[QuantumCircuitOperator[{"Controlled", qo, {i + m}}], 2 ^ (n - i)], {i, n}]
    ],
    QuantumCircuitOperator[{"InverseFourier", n}],
    Splice @ Table[QuantumMeasurementOperator[{i + m}], {i, n}]
},
    opts,
    "Label" -> "Phase Estimation"
]

QuantumCircuitOperator[{"C" | "Controlled", qc_ ? QuantumCircuitOperatorQ, control1 : _ ? orderQ | Automatic : Automatic, control0 : _ ? orderQ : {}}, opts___] :=
    QuantumCircuitOperator[If[QuantumOperatorQ[#] || QuantumCircuitOperatorQ[#], Head[#][{"Controlled", #, control1, control0}], #] & /@ qc["Elements"], Subscript["C", qc["Label"]][control1, control0]]

QuantumCircuitOperator[{"C" | "Controlled", qc_ : "Magic", control1 : _ ? orderQ | Automatic : Automatic, control0 : _ ? orderQ : {}}, opts___] :=
    QuantumCircuitOperator[{"C", QuantumCircuitOperator @ FromCircuitOperatorShorthand[qc], control1, control0}, opts]


QuantumCircuitOperator[pauliString_String, opts___] := With[{chars = Characters[pauliString]},
    QuantumCircuitOperator[MapIndexed[QuantumOperator, chars], opts] /; ContainsOnly[chars, {"I", "X", "Y", "Z", "H", "S", "T", "V", "P"}]
]


trotterCoeffs[l_, 1, c_ : 1] := ConstantArray[c, l]
trotterCoeffs[l_, 2, c_ : 1] := With[{s = trotterCoeffs[l, 1, c / 2]}, Join[s, Reverse[s]]]
trotterCoeffs[l_, n_ ? EvenQ, c_ : 1] := With[{p = 1 / (4 - 4 ^ (1 / (n - 1)))},
	With[{s = trotterCoeffs[l, n - 2, c p]}, Join[s, s, trotterCoeffs[l, n - 2, (1 - 4 p) c], s, s]]
]
trotterCoeffs[l_, n_ ? OddQ, c_ : 1] := trotterCoeffs[l, Round[n, 2], c]

trotterExpand[l_List, 1] := l
trotterExpand[l_List, 2] := Join[l, Reverse[l]]
trotterExpand[l_List, n_ ? EvenQ] := Catenate @ Table[trotterExpand[l, n - 2], 5]
trotterExpand[l_List, n_ ? OddQ] := trotterExpand[l, Round[n, 2]]

Trotterization[ops : {__QuantumOperator}, order : _Integer ? Positive : 1, reps : _Integer ? Positive : 1, const_ : 1] := Block[{
    coeffs = const * trotterCoeffs[Length[ops], order, 1 / reps],
	newOps
},
    newOps = MapThread[
        QuantumOperator[Exp[- I #1], "Label" -> Subscript["R", #2][2 #3]] &,
        {
            Thread[Times[coeffs, trotterExpand[ops, order]]],
            trotterExpand[Through[ops["Label"]], order],
            coeffs
        }
    ];
	Table[newOps, reps]
]

QuantumCircuitOperator[{"Trotterization", opArgs_ : {"X", "Y", "Z"}, args___}, opts___] := Block[{
    ops = QuantumCircuitOperator[opArgs]["Flatten"]["Operators"],
    trotterization
},
    trotterization = Trotterization[ops, args];
    QuantumCircuitOperator[
        If[ Length[trotterization] > 1,
            MapIndexed[QuantumCircuitOperator[#1, First[#2]] &, trotterization],
            Catenate[trotterization]
        ],
        opts,
        "Label" -> "Trotterization"
    ]
]

QuantumCircuitOperator["Magic", opts___] := QuantumCircuitOperator[{"S" -> 1, "S" -> 2, "H" -> 2, "CNOT" -> {2, 1}}, opts, "Label" -> "Magic"]


QuantumCircuitOperator[{"Multiplexer"| "Multiplexor"}, opts___] := QuantumCircuitOperator[{"Multiplexer", "X", "Y", "Z"}, opts]

QuantumCircuitOperator[{"Multiplexer"| "Multiplexor", ops__} -> defaultK : _Integer ? Positive | Automatic : Automatic, opts___] := Block[{
    n = Length[{ops}],
    m, k, seq
},
    m = Ceiling[Log2[n]];
    k = Replace[defaultK, Automatic :> m + 1];
    seq = Values[<|0 -> {}, 1 -> {}, PositionIndex[#]|>] & /@ Take[Tuples[{1, 0}, m], n];
    QuantumCircuitOperator[
        MapThread[
            If[MatchQ[#1["Label"], "I" | CircleTimes["I" ..] | Superscript["I", _CircleTimes]], Nothing, {"C", #1, Splice[#2 /. c_Integer /; c == k :> m + 1]}] &,
            {QuantumOperator /@ {ops}, seq}
        ],
        opts,
        "Label" -> "Multiplexer"
    ]
]

QuantumCircuitOperator[{"Multiplexer"| "Multiplexor", ops__}, opts___] := QuantumCircuitOperator[{"Multiplexer", ops} -> Automatic, opts]

QuantumCircuitOperator[{"ControlledMultiplexer", matrix : _ ? MatrixQ : RandomReal[1, {4, 4}], vector : _ ? VectorQ : RandomReal[1, 4]}] :=
    QuantumLinearSolve[matrix, vector, "CircuitOperator"]


RZY[vec_ ? VectorQ] := Block[{a, b, phi, psi, y, z, phase},
    If[Length[vec] == 0, Return[{}]];
    {{a, phi}, {b, psi}} = AbsArg[Simplify[Normal[vec]]];
    phase = Sow[phi + psi, "Phase"];
    y = Simplify[If[TrueQ[Simplify[a == b == 0]], Pi / 2, 2 ArcSin[(a - b) / Sqrt[2 (a ^ 2 + b ^ 2)]]]];
    z = Simplify[phi - psi];
    Replace[
        {If[TrueQ[Chop[z] == 0], Nothing, {"RZ", z}], If[TrueQ[Chop[y] == 0], Nothing, {"RY", y}]},
        {} -> {"I"}
    ]
]


multiplexer[qs_, n_, i_] := Block[{rzy, rzyDagger, qc, multiplexer, multiplexerDagger},
    rzy = RZY /@ Partition[qs["StateVector"], 2];
    rzyDagger = Reverse /@ rzy /. {r : "RZ" | "RY", angle_} :> {r, - angle};
    {multiplexer, multiplexerDagger} = {"Multiplexer", Splice[#]} & /@ {rzy, rzyDagger};
    qc = If[i === 0,
        QuantumCircuitOperator[{multiplexer, Splice["H" -> # & /@ Range[qs["Qudits"]]]}],
        QuantumCircuitOperator[{multiplexer, {"Permutation", Cycles[{{n, i}}]}}]
    ];
    Sow[
        If[i === 0,
            {multiplexerDagger, Splice["H" -> # & /@ Range[qs["Qudits"]]]},
            {multiplexerDagger, {"Permutation", Cycles[{{n, i}}]}}
        ],
        "Operators"
    ];
    qc[qs]
]

stateEvolution[qs_] := With[{n = qs["Qudits"]},
    FoldList[multiplexer[#1, n, #2] &, qs, Range[n - 1, 0, -1]]
]


Options[QuantumStatePreparation] = Join[{Method -> Automatic}, Options[QuantumStateMultiplexer], Options[ClassiqQuantumState]]

QuantumStatePreparation[qs_QuantumState, opts: OptionsPattern[]] /; MatchQ[qs["Dimensions"], {2 ..}] := Switch[OptionValue[Method],
    Automatic,
    QuantumStateMultiplexer[qs["Computational"], FilterRules[{opts}, Options[QuantumStateMultiplexer]]],
    "Classiq",
    ClassiqQuantumState[qs["Computational"], FilterRules[{opts}, Options[ClassiqQuantumState]]]
]

QuantumStateMultiplexer[qs_QuantumState, ___]  := Block[{
    operators, phases, phase, n = qs["Qudits"]
},
    {operators, phases} = Reap[stateEvolution[qs["Split", n]], {"Operators", "Phase"}][[2, All, 1]];
    phase = Total[phases] / n / 2 ^ n - I Log[qs["Norm"]];
    operators = Reverse @ Catenate @ operators;
    If[ TrueQ[Chop[phase] != 0],
        AppendTo[operators, {"GlobalPhase", phase}]
    ];
    operators = Join["0" -> # & /@ Range[n], operators];
    If[ qs["InputQudits"] > 0,
        operators = Join[
            "I" -> # -> n + # & /@ Range[qs["InputQudits"]],
            operators,
            "Cap" -> {qs["OutputQudits"] + #, n + #} & /@ Range[qs["InputQudits"]]
        ]
    ];
    QuantumCircuitOperator[operators, "Label" -> qs["Label"]]["Flatten"]
]

QuantumCircuitOperator[qs_QuantumState | {"QuantumState", qs_QuantumState, args___}, opts___] /; MatchQ[qs["Dimensions"], {2 ..}] :=
    Enclose @ QuantumCircuitOperator[
        ConfirmBy[QuantumStatePreparation[qs, args], QuantumCircuitOperatorQ],
        opts
    ]

QuantumCircuitOperator["QuantumState", opts___] := QuantumCircuitOperator[{"QuantumState", QuantumState[{"UniformSuperposition", 3}]}, opts]


QuantumCircuitOperator[{"CHSH", theta_ : Pi / 4}, opts___] :=
    QuantumCircuitOperator[{
        QuantumOperator["Cup" / Sqrt[2], {1, 4}, "Label" -> "Cup"],
        QuantumCircuitOperator[{"+" -> 2, "+" -> 3}, "Charlie"],
        "Barrier",
        QuantumCircuitOperator[{"I", {"C", "H"} -> {2, 1}}, "Alice"],
        QuantumCircuitOperator[{{"RY", theta} -> 4, {"C0", "H"} -> {3, 4}}, "Bob"],
        "Barrier",
        {1}, {2}, {3}, {4}
    },
        opts,
        "Label" -> "CHSH"
    ]


QuantumCircuitOperator[{"LeggettGarg", theta_ : Pi / 4}, opts___] := QuantumCircuitOperator[{
        QuantumCircuitOperator[{"+" -> 2, "+" -> 3}, "Charlie"], "Barrier",
        QuantumCircuitOperator[{{"C", "H"} -> {2, 1}, {1}, {"C", "H"}}, "Alice"], "Barrier", 
        QuantumCircuitOperator[{"RY"[theta], {"C0", "H"} -> {3, 1}}, "Bob"], "Barrier", {1}, {2}, {3}
    },
    opts,
    "Label" -> "Leggett-Garg"
]

QuantumCircuitOperator[{"WignerCHSH", theta_ : Pi / 4}, opts___] := Block[{
    basis = QuditBasis[CharacterRange["a", "d"], QuditBasis["WignerMIC"]["Elements"]],
    Bell, Alice, Bob, Charlie, M
},
    Bell = Simplify @ QuantumState[QuantumState["Bell"]["Double"], QuantumBasis[QuantumTensorProduct[basis, basis], "Label" -> "Cup"]];
    Alice = Simplify @ QuantumOperator[QuantumOperator[{"C", "Double"["H"]}, {2, 1}]["Sort"], QuantumBasis[QuditBasis[{basis, 2}], QuantumTensorProduct[basis, QuditBasis[2]]], "Label" -> "Alice"];
    Bob = Simplify @ QuantumOperator[QuantumOperator[{"C0", "Double"["H"]} -> {3, 4}] @ QuantumOperator["RY"[theta] -> 4]["Double"], QuantumBasis[QuditBasis[{2, basis}], QuantumTensorProduct[QuditBasis[2], basis]], "Label" -> "Bob"];
    Charlie = QuantumCircuitOperator[{QuantumState["+"] / Sqrt[2] -> 2, QuantumState["+"] / Sqrt[2] -> 3}, "Charlie"];
    M = QuantumOperator[QuantumOperator["Spider"[QuantumBasis[{2}, {4}]], QuantumBasis[QuditBasis[2], basis]], "Label" -> "Measure"];
    QuantumCircuitOperator[{
        Bell -> {1, 4},
        Charlie,
        Alice, Bob,
        M -> 1, M -> 4
    },
        opts,
        "Label" -> "WignerCHSH"
    ]
]


QuantumCircuitOperator[name_String | name_String[args___], opts___] /; MemberQ[$QuantumCircuitOperatorNames, name] := QuantumCircuitOperator[{name, args}, opts]

