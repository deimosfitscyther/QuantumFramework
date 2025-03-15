Package["Wolfram`QuantumFramework`"]

PackageScope["$QuantumChannelNames"]



$QuantumChannelNames = {
    "BitFlip", "PhaseFlip", "BitPhaseFlip", "Depolarizing",
    "AmplitudeDamping", "GeneralizedAmplitudeDamping",
    "PhaseDamping", "ResetError"
}

quantumChannel[qo_ ? QuantumOperatorQ] := Enclose @ QuantumChannel @
    Confirm @ QuantumOperator[
        qo,
        {
            Prepend[qo["InputOrder"], Last[Complement[Range[Min[1, qo["InputOrder"]] - 1, 0], Select[qo["InputOrder"], NonPositive]], 0]],
            qo["InputOrder"]
        },
        "Output" -> QuditBasis @ KeyMap[Replace[{qn_QuditName, 1} :> {QuditName[Subscript["\[ScriptCapitalK]", qn["Name"]]], 1}]] @
            qo["Output"]["Representations"]
    ]

quantumChannel[ops_List, order : _ ? orderQ : {1}, basisArgs___] := Enclose @ With[{
    basis = QuantumBasis[basisArgs]
},
    ConfirmAssert[AllTrue[order, Positive], "Channel input order should only contain positive integers."];
    quantumChannel @ Confirm @ QuantumOperator[
        QuantumState[
            Flatten[kroneckerProduct @@@ Tuples[ops, Length[order]]],
            QuantumTensorProduct[
                QuantumBasis[Length[ops] ^ Length[order]],
                QuantumBasis[QuantumBasis[basis["Output"], basis["Output"]], Length[order]]
            ],
            basis["Options"]
        ],
        {Prepend[order, 0], order}
    ]
]

quantumChannel[args___] := quantumChannel[QuantumOperator[args]]


QuantumChannel[{"AmplitudeDamping", gamma_ : .5}, args___] :=
    quantumChannel[{{{1, 0}, {0, Sqrt[1 - gamma]}}, {{0, Sqrt[gamma]}, {0, 0}}}, args, "Label" -> "AmplitudeDamping"[gamma]]

QuantumChannel[{"GeneralizedAmplitudeDamping", gamma_ : .5, p_ : .5}, args___] :=
	quantumChannel[{
        Sqrt[p] {{1, 0}, {0, Sqrt[1 - gamma]}},
        Sqrt[p] {{0, Sqrt[gamma]}, {0, 0}},
        Sqrt[1 - p] {{Sqrt[1 - gamma], 0}, {0, 1}},
        Sqrt[1 - p] {{0, 0}, {Sqrt[gamma], 0}}
    },
        args,
        "Label" -> "GeneralizedAmplitudeDamping"[gamma, p]
    ]

QuantumChannel[{"PhaseDamping", lambda_ : .5}, args___] :=
    quantumChannel[{{{1, 0}, {0, Sqrt[1 - lambda]}}, {{0, 0}, {0, Sqrt[lambda]}}}, args, "Label" -> "PhaseDamping"[lambda]]


QuantumChannel[{"BitFlip", p_ : .5}, args___] :=
    quantumChannel[{Sqrt[1 - p] IdentityMatrix[2], Sqrt[p] {{0, 1}, {1, 0}}}, args, "Label" -> "BitFlip"[p]]

QuantumChannel[{"PhaseFlip", p_ : .5}, args___] :=
    quantumChannel[{Sqrt[1 - p] IdentityMatrix[2], Sqrt[p] {{1, 0}, {0, -1}}}, args, "Label" -> "PhaseFlip"[p]]

QuantumChannel[{"BitPhaseFlip", p_ : .5}, args___] :=
    quantumChannel[{Sqrt[1 - p] IdentityMatrix[2], Sqrt[p] {{0, -I}, {I ,0}}}, args, "Label" -> "BitPhaseFlip"[p]]

QuantumChannel[{"Depolarizing", p_ : .5}, args___] :=
    quantumChannel[{
        Sqrt[1 - 3 p / 4] PauliMatrix[0],
        Sqrt[p] (1 / 2) PauliMatrix[1],
        Sqrt[p] (1 / 2) PauliMatrix[2],
        Sqrt[p] (1 / 2) PauliMatrix[3]
    },
        args,
        "Label" -> "\[CapitalDelta]"[p]
    ]

QuantumChannel[{"ResetError", p0_ : .25, p1_ : .25}, args___] :=
    quantumChannel[{
        Sqrt[1 - p0 - p1] IdentityMatrix[2],
        Sqrt[p0] {{1, 0}, {0, 0}},
        Sqrt[p0] {{0, 1}, {0, 0}},
        Sqrt[p1] {{0, 0}, {1, 0}},
        Sqrt[p1] {{0, 0}, {0, 1}}
    },
        args,
        "Label" -> "ResetError"[p0, p1]
    ]

QuantumChannel[name_String, args___] := QuantumChannel[{name}, args]

QuantumChannel[name_String[args___], opts___] := QuantumChannel[{name, args}, opts]

QuantumChannel[name_ -> order_, opts___] := QuantumChannel[name, Flatten[{order}], opts]


