Package["Wolfram`QuantumFramework`"]

PackageExport["QuantumState"]

PackageScope["quantumStateQ"]
PackageScope["QuantumStateQ"]
PackageScope["addQuantumStates"]



quantumStateQ[QuantumState[state_SparseArray ? stateQ, qb_QuantumBasis /; QuantumBasisQ[Unevaluated[qb]]]] := Length[state] === qb["Dimension"]

quantumStateQ[___] := False


QuantumStateQ[qs_QuantumState] := System`Private`HoldValidQ[qs] || quantumStateQ[Unevaluated[qs]]

QuantumStateQ[___] := False


qs_QuantumState /; System`Private`HoldNotValidQ[qs] && quantumStateQ[Unevaluated[qs]] := System`Private`HoldSetValid[qs]


(* basis argument input *)

QuantumState[state_ ? stateQ] := QuantumState[state, QuantumBasis[primeFactors[Length[state]]]]

QuantumState[state_ ? stateQ, basisArgs__] /; ! QuantumBasisQ[basisArgs] := Enclose @ Block[{
    basis, multiplicity
},
    basis = ConfirmBy[QuantumBasis[basisArgs], QuantumBasisQ];
    multiplicity = basisMultiplicity[Length[state], basis["Dimension"]];
    basis = ConfirmBy[QuantumBasis[basis, multiplicity], QuantumBasisQ];
    QuantumState[
        PadRight[state, Table[basis["Dimension"], TensorRank[state]]],
        basis
    ]
]


(* association input *)

QuantumState[state_ ? AssociationQ, basisArgs___] /; VectorQ[Values[state]] := Enclose @ Module[{
    basis = ConfirmBy[QuantumBasis[basisArgs], QuantumBasisQ], multiplicity},
    multiplicity = basisMultiplicity[Length[state], basis["Dimension"]];
    basis = ConfirmBy[QuantumBasis[basis, multiplicity], QuantumBasisQ];
    ConfirmAssert[ContainsOnly[QuditName /@ Keys[state], basis["ElementNames"]], "Association keys and basis names don't match"];
    QuantumState[
        Values @ KeyMap[QuditName, state][[Key /@ basis["ElementNames"]]] /. _Missing -> 0,
        basis
    ]
]


(* eigenvalues input *)

QuantumState["Eigenvalues" -> eigenvalues_ ? VectorQ, basisArgs___] := With[{
    basis = QuantumBasis[basisArgs]
},
    QuantumState[
        Total @ MapThread[#1 #2 &, {eigenvalues, basis["Projectors"]}],
        basis
    ] /; Length[eigenvalues] == basis["Dimension"]
]

(* conversion *)

QuantumState[obj : _QuantumOperator | _QuantumMeasurementOperator | _QuantumMeasurement | _QuantumChannel | _QuantumCircuitOperator, opts___] :=
    QuantumState[obj["State"], opts]


(* active basis transform *)

QuantumState[qb_QuditBasis, opts___] := QuantumState[QuantumBasis[qb], opts]

QuantumState[qb_ ? QuantumBasisQ, opts___] := Enclose @ If[
    qb["Picture"] === "PhaseSpace",

    With[{dims = Sqrt[qb["Dimensions"]], n = qb["Qudits"]},
        ConfirmAssert[AllTrue[dims, IntegerQ]];
        QuantumState[
            ArrayReshape[
                Transpose[
                    ArrayReshape[Inverse[qb["Matrix"]], Join[#, #] & @ Catenate[{#, #} & /@ dims]],
                    If[ n > 1,
                        PermutationProduct[
                            Cycles[NestList[# + 2 &, {2, 2 n + 1 }, n - 1]],
                            Cycles[NestList[# + 4 &, {2, 3}, n - 1]]
                        ],
                        Cycles[{{2, 3}}]
                    ]
                ],
                {#, #} & @ qb["Dimension"]
            ],
            QuantumBasis[dims, dims, opts, qb["Options"]]
        ]
    ],

    QuantumState[Flatten[Inverse[qb["Matrix"]]], QuantumBasis[qb["QuditBasis"], qb["Dimensions"], opts, qb["Options"]]]
]


(* number *)

QuantumState[x : Except[_ ? QuantumStateQ | _ ? stateQ], basisArgs___] := QuantumState[{x}, QuantumBasis[basisArgs]]


(* expand basis *)

QuantumState[state : Except[_ ? QuantumStateQ], args : Except[_ ? QuantumBasisQ]] :=
    Enclose @ QuantumState[state, ConfirmBy[QuantumBasis[args], QuantumBasisQ]]

QuantumState[state_ ? stateQ, basis_ ? QuantumBasisQ] := QuantumState[
    state,
    QuantumTensorProduct[basis, QuantumBasis[Max[2, Length[state] - basis["Dimension"]]]]
] /; Length[state] > basis["Dimension"] > 0


(* pad state *)

QuantumState[state_ ? stateQ, basis_ ? QuantumBasisQ] := QuantumState[
    PadRight[state, Table[basis["Dimension"], TensorRank[state]]],
    basis
] /; Length[state] < basis["Dimension"]


(* Mutation *)

QuantumState[state_ ? stateQ, basis_ ? QuantumBasisQ] /; !SparseArrayQ[state] && state =!= {} :=
    Enclose @ QuantumState[ConfirmBy[SparseArray[state, Length[state]], SparseArrayQ], basis]

QuantumState[qs_ ? QuantumStateQ, args : Except[_ ? QuantumBasisQ, Except[Alternatives @@ $QuantumBasisPictures, _ ? nameQ | _Integer]]] :=
    Enclose @ QuantumState[qs, ConfirmBy[QuantumBasis[args], QuantumBasisQ]]

QuantumState[qs_ ? QuantumStateQ, args : PatternSequence[Except[_ ? QuantumBasisQ | _ ? QuantumStateQ], ___]] :=
    Enclose @ QuantumState[qs, ConfirmBy[QuantumBasis[qs["Basis"], args], QuantumBasisQ]]


(* change of basis *)

QuantumState[qs_ ? QuantumStateQ, newBasis_ ? QuantumBasisQ] /; ! newBasis["SortedQ"] := QuantumState[qs, newBasis["Sort"]]

QuantumState[qs_ ? QuantumStateQ, newBasis_ ? QuantumBasisQ] /; qs["Basis"] == newBasis || qs["ComputationalQ"] && newBasis["ComputationalQ"] := QuantumState[qs["State"], newBasis]

QuantumState[qs_ ? QuantumStateQ, newBasis_ ? QuantumBasisQ] /; qs["Dimension"] == newBasis["Dimension"] :=
    Enclose[Which[
        qs["Dimension"] == 0,
        QuantumState[qs["State"], newBasis],
        qs["VectorQ"],
        QuantumState[
            SparseArrayFlatten @ ConfirmQuiet[
                Dot[
                    MatrixInverse[newBasis["Output"]["ReducedMatrix"]],
                    qs["Output"]["ReducedMatrix"] . qs["StateMatrix"] . MatrixInverse[qs["Input"]["ReducedMatrix"]],
                    newBasis["Input"]["ReducedMatrix"]
                ],
                Dot::dotsh
            ],
            newBasis
        ],
        qs["MatrixQ"],
        QuantumState[
            ConfirmQuiet[
                Dot[
                    MatrixInverse[newBasis["ReducedMatrix"]],
                    qs["Basis"]["ReducedMatrix"] . qs["DensityMatrix"] . MatrixInverse[qs["Basis"]["ReducedMatrix"]],
                    newBasis["ReducedMatrix"]
                ],
                Dot::dotsh
            ],
            newBasis
        ],
        True,
        $Failed
    ],
    (ReleaseHold[#["HeldMessageCall"]]; Throw[$Failed]) &
]

QuantumState[qs_ ? QuantumStateQ, newBasis_ ? QuantumBasisQ] := Switch[
    qs["StateType"],
    "Vector",
    QuantumState[PadRight[qs["State"], newBasis["Dimension"]], newBasis],
    "Matrix",
    QuantumState[PadRight[qs["State"], {newBasis["Dimension"], newBasis["Dimension"]}], newBasis]
]

QuantumState[qs_ ? QuantumStateQ, newBasis_ ? QuantumBasisQ, opts__] :=
    QuantumState[qs, QuantumBasis[newBasis, opts]]


(* equality *)

QuantumState /: Equal[qs__QuantumState] :=
    Which[
        And @@ (#["VectorStateQ"] & /@ {qs}),
        Thread[Equal @@ (Chop @ SetPrecisionNumeric[#["Computational"]["CanonicalStateVector"]] & /@ {qs})],
        And @@ (#["MatrixStateQ"] & /@ {qs}),
        Thread[Equal @@ (Chop @ SetPrecisionNumeric[SparseArrayFlatten @ #["NormalizedMatrixRepresentation"]] & /@ {qs})],
        True,
        Thread[Equal @@ Through[{qs}["MatrixState"]]]
    ]

QuantumState /: Unequal[qs__QuantumState] := ! Equal[qs]


(* numeric function *)

QuantumState /: f_Symbol[left : Except[_QuantumState] ..., qs_QuantumState, right : Except[_QuantumState] ...] /; MemberQ[Attributes[f], NumericFunction] :=
    Enclose @ QuantumState[
        If[ MemberQ[{Minus, Times}, f],
            ConfirmBy[f[left, qs["State"], right], stateQ],
            ConfirmBy[Check[MatrixFunction[f[left, #, right] &, qs["DensityMatrix"], Method -> "Jordan"], MatrixFunction[f[left, #, right] &, qs["DensityMatrix"]]], MatrixQ]
        ],
        qs["Basis"]
    ]

(* Trace *)

QuantumState /: Tr[qs_QuantumState] := Tr @ qs["DensityMatrix"]


(* addition *)

addQuantumStates[qs1_QuantumState ? QuantumStateQ, qs2_QuantumState ? QuantumStateQ] /; qs1["Dimension"] == qs2["Dimension"] :=
    QuantumState[
        If[ qs1["StateType"] === qs2["StateType"] === "Vector",
            qs1["StateVector"] + QuantumState[qs2, qs1["Basis"]]["StateVector"],
            qs1["DensityMatrix"] + QuantumState[qs2, qs1["Basis"]]["DensityMatrix"]
        ],
        qs1["Basis"],
        "ParameterSpec" -> MergeParameterSpecs[qs1, qs2]
    ]

QuantumState /: HoldPattern[Plus[states__QuantumState]] /; Length[{states}] > 1 :=
    If[ Equal @@ (#["Dimension"] & /@ {states}), Fold[addQuantumStates, {states}],
        Failure["QuantumState", <|"MessageTemplate" -> "Incompatible dimensions"|>]
    ]


(* multiplication *)

multiplyQuantumStates[qs1_QuantumState, qs2_QuantumState] /; qs1["Dimension"] == qs2["Dimension"] :=
    QuantumState[
        QuantumState[
            If[ qs1["StateType"] === qs2["StateType"] === "Vector",
                qs1["VectorRepresentation"] * qs2["VectorRepresentation"],
                qs1["MatrixRepresentation"] * ArrayReshape[qs2["MatrixRepresentation"], Dimensions @ qs1["MatrixRepresentation"]]
            ],
            QuantumBasis[qs1["Dimensions"]]
        ],
        qs1["Basis"],
        "ParameterSpec" -> MergeParameterSpecs[qs1, qs2]
    ]

QuantumState /: HoldPattern[Times[states : _QuantumState ? QuantumStateQ ...]] :=
    If[ Equal @@ (#["Dimension"] & /@ {states}), Fold[multiplyQuantumStates, {states}],
        Failure["QuantumState", <|"MessageTemplate" -> "Incompatible dimensions"|>]
    ]


(* differentiation *)

QuantumState /: D[qs : _QuantumState, args___] := QuantumState[D[qs["State"], args], qs["Basis"]]


(* duals *)

SuperDagger[qs_QuantumState] ^:= qs["Dagger"]

SuperStar[qs_QuantumState] ^:= qs["Conjugate"]

Transpose[qs_QuantumState, args___] ^:= qs["Transpose", args]

Inverse[qs_QuantumState] ^:= qs ^ -1


(* simplify *)

Scan[
    (Symbol[#][qs_QuantumState, args___] ^:= qs[#, args]) &,
    {"Simplify", "FullSimplify", "Chop", "ComplexExpand"}
]


(* join *)

QuantumState[qs_QuantumState ? QuantumStateQ] := qs

QuantumState[qs__QuantumState ? QuantumStateQ] := QuantumState[
    If[ And @@ (#["PureStateQ"] & /@ {qs}),
        SparseArrayFlatten[blockDiagonalMatrix[#["StateMatrix"] & /@ {qs}]],
        blockDiagonalMatrix[#["DensityMatrix"] & /@ {qs}]
    ],
    Plus @@ (#["Basis"] & /@ {qs}),
    "Label" -> CirclePlus @@ (#["Label"] & /@ {qs}),
    "ParameterSpec" -> MergeParameterSpecs[qs1, qs2]
]


(* composition *)


(top_QuantumState ? QuantumStateQ)[(bot_QuantumState ? QuantumStateQ)] := (QuantumOperator[top] @ QuantumOperator[bot])["Sort"]["State"]


(qs1_QuantumState ? QuantumStateQ)[(qs2_QuantumState ? QuantumStateQ)] /; qs1["InputDimension"] == qs2["OutputDimension"] := Module[{
    q1 = qs1["Computational"], q2 = qs2["Computational"], state
},
    state = Which[
        qs1["OutputDimension"] * qs2["InputDimension"] == 0,
        {},
        TrueQ[qs1["VectorQ"] && qs2["VectorQ"]],
        SparseArrayFlatten[q1["StateMatrix"] . q2["StateMatrix"]],
        True,
        q1 = q1["Double"];
        q2 = q2["Double"];
        ArrayReshape[
            q1["StateMatrix"] . q2["StateMatrix"],
            Table[qs1["OutputDimension"] qs2["InputDimension"], 2]
        ]
    ];
    With[{
        s = QuantumState[state, "Output" -> QuditBasis @ qs1["OutputDimensions"], "Input" -> QuditBasis @ qs2["InputDimensions"]],
        b = QuantumBasis[
            "Output" -> qs1["Output"], "Input" -> qs2["Input"],
            "Label" -> qs1["Label"] @* qs2["Label"],
            "Picture" -> If[MemberQ[{qs1["Picture"], qs2["Picture"]}, "PhaseSpace"], "PhaseSpace", qs1["Picture"]],
            "ParameterSpec" -> MergeParameterSpecs[qs1, qs2]
    ]},
        QuantumState[s, b]
    ]
]


(* parameterization *)

(qs_QuantumState ? QuantumStateQ)[ps : PatternSequence[p : Except[_Association], ___]] /; ! MemberQ[QuantumState["Properties"], p] && Length[{ps}] <= qs["ParameterArity"] :=
    qs[AssociationThread[Take[qs["Parameters"], UpTo[Length[{ps}]]], {ps}]]

(qs_QuantumState ? QuantumStateQ)[rules_ ? AssociationQ] /; ContainsOnly[Keys[rules], qs["Parameters"]] :=
    QuantumState[
        Map[ReplaceAll[rules], qs["State"], {If[qs["VectorQ"], 1, 2]}],
        qs["Basis"][rules]
    ]

