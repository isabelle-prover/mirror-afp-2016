(*****************************************************************************
 * ISABELLE COPYRIGHT NOTICE, LICENCE AND DISCLAIMER.
 *
 * Copyright (c) 1986-2015 University of Cambridge,
 *                         Technische Universitaet Muenchen,
 *                         and contributors.
 *               2013-2015 Université Paris-Saclay, Univ. Paris-Sud, France
 *               2013-2015 IRT SystemX, France
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *
 *     * Neither the name of the copyright holders nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ******************************************************************************)

chapter{* Part ... *}

theory Isabelle_fun
imports Isabelle_function_common
  keywords "fun'" :: thy_decl
begin

section{* ... *}

ML{*
structure Isabelle_Function_Fun =
struct
(*  Title:      HOL/Tools/Function/fun.ML
    Author:     Alexander Krauss, TU Muenchen

Command "fun": Function definitions with pattern splitting/completion
and automated termination proofs.
*)
  val _ =
    Outer_Syntax.local_theory' @{command_keyword fun'}
      "define general recursive functions (short version)"
      (Isabelle_Function_Common.function_parser 
        >> (fn (fixes, statements) => Function_Fun.add_fun_cmd fixes statements Function_Fun.fun_config))
end
*}

end
