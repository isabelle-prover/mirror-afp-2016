(*
  File:   Landau_Simprocs.thy
  Author: Manuel Eberl <eberlm@in.tum.de>

  Simplification procedures for Landau symbols, with a particular focus on functions into the reals.
*)
section {* Simplification procedures *}

theory Landau_Simprocs
imports Landau_Symbols_Definition Landau_Real_Products
begin

subsection {* Simplification under Landau symbols *}

text {* 
  The following can be seen as simpset for terms under Landau symbols. 
  When given a rule @{term "f \<in> \<Theta>(g)"}, the simproc will attempt to rewrite any occurrence of 
  @{term "f"} under a Landau symbol to @{term "g"}.
*}

named_theorems landau_simp "BigTheta rules for simplification of Landau symbols"
setup {*
  let
    val eq_thms = @{thms landau_theta.cong_bigtheta}
    fun eq_rule thm = get_first (try (fn eq_thm => eq_thm OF [thm])) eq_thms
  in
    Global_Theory.add_thms_dynamic
      (@{binding landau_simps},
        fn context =>
          Named_Theorems.get (Context.proof_of context) @{named_theorems landau_simp}
          |> map_filter eq_rule)
  end;
*}


lemma bigtheta_const [landau_simp]:
  "NO_MATCH 1 c \<Longrightarrow> c \<noteq> 0 \<Longrightarrow> (\<lambda>x. c) \<in> \<Theta>(\<lambda>x. 1)" by simp

lemmas [landau_simp] = bigtheta_const_ln bigtheta_const_ln_powr bigtheta_const_ln_pow

lemma bigtheta_const_ln' [landau_simp]: 
  "0 < a \<Longrightarrow> (\<lambda>x::real. ln (x * a)) \<in> \<Theta>(ln)"
  by (subst mult.commute) (rule bigtheta_const_ln)

lemma bigtheta_const_ln_powr' [landau_simp]: 
  "0 < a \<Longrightarrow> (\<lambda>x::real. ln (x * a) powr p) \<in> \<Theta>(\<lambda>x. ln x powr p)"
  by (subst mult.commute) (rule bigtheta_const_ln_powr)

lemma bigtheta_const_ln_pow' [landau_simp]: 
  "0 < a \<Longrightarrow> (\<lambda>x::real. ln (x * a) ^ p) \<in> \<Theta>(\<lambda>x. ln x ^ p)"
  by (subst mult.commute) (rule bigtheta_const_ln_pow)



subsection {* Simproc setup *}


lemma landau_gt_1_cong: 
  "landau_symbol L \<Longrightarrow> (\<And>x::real. x > 1 \<Longrightarrow> f x = g x) \<Longrightarrow> L(f) = L(g)"
  using eventually_gt_at_top[of "1::real"] by (auto elim!: eventually_mono landau_symbol.cong)

lemma landau_gt_1_in_cong: 
  "landau_symbol L \<Longrightarrow> (\<And>x::real. x > 1 \<Longrightarrow> f x = g x) \<Longrightarrow> f \<in> L(h) \<longleftrightarrow> g \<in> L(h)"
  using eventually_gt_at_top[of "1::real"] by (auto elim!: eventually_mono landau_symbol.in_cong)

lemma landau_prop_equalsI:
  "landau_symbol L \<Longrightarrow> (\<And>x::real. x > 1 \<Longrightarrow> f1 x = f2 x) \<Longrightarrow> (\<And>x. x > 1 \<Longrightarrow> g1 x = g2 x) \<Longrightarrow> 
     f1 \<in> L(g1) \<longleftrightarrow> f2 \<in> L(g2)"
apply (subst landau_gt_1_cong, assumption+)
apply (subst landau_gt_1_in_cong, assumption+)
apply (rule refl)
done


lemma ab_diff_conv_add_uminus': "(a::_::ab_group_add) - b = -b + a" by simp
lemma extract_diff_middle: "(a::_::ab_group_add) - (x + b) = -x + (a - b)" by simp

lemma divide_inverse': "(a::_::{division_ring,ab_semigroup_mult}) / b = inverse b * a"
  by (simp add: divide_inverse mult.commute)
lemma extract_divide_middle:"(a::_::{field}) / (x * b) = inverse x * (a / b)"
  by (simp add: divide_inverse algebra_simps)

lemmas landau_cancel = landau_symbol.mult_cancel_left

lemmas mult_cancel_left' = landau_symbol.mult_cancel_left[OF _ bigtheta_refl eventually_nonzeroD]

lemma mult_cancel_left_1:
  assumes "landau_symbol L" "eventually_nonzero f"
  shows   "f \<in> L(\<lambda>x. f x * g2 x) \<longleftrightarrow> (\<lambda>_. 1) \<in> L(g2)"
          "(\<lambda>x. f x * f2 x) \<in> L(f) \<longleftrightarrow> f2 \<in> L(\<lambda>_. 1)"
          "f \<in> L(f) \<longleftrightarrow> (\<lambda>_. 1) \<in> L(\<lambda>_. 1)"
  using mult_cancel_left'[OF assms, of "\<lambda>_. 1"] mult_cancel_left'[OF assms, of _ "\<lambda>_. 1"]
        mult_cancel_left'[OF assms, of "\<lambda>_. 1" "\<lambda>_. 1"] by simp_all

lemmas landau_mult_cancel_simps = mult_cancel_left' mult_cancel_left_1

ML_file "landau_simprocs.ML"

lemmas bigtheta_simps = 
  landau_theta.cong_bigtheta[OF bigtheta_const_ln]
  landau_theta.cong_bigtheta[OF bigtheta_const_ln_powr]


simproc_setup landau_cancel_factor (
    "f \<in> o(g)" | "f \<in> O(g)" | "f \<in> \<omega>(g)" | "f \<in> \<Omega>(g)" | "f \<in> \<Theta>(g)"
  ) = {* K Landau.cancel_factor_simproc *}

simproc_setup simplify_landau_sum (
    "o(\<lambda>x. f x)" | "O(\<lambda>x. f x)" | "\<omega>(\<lambda>x. f x)" | "\<Omega>(\<lambda>x. f x)" | "\<Theta>(\<lambda>x. f x)" |
    "f \<in> o(g)" | "f \<in> O(g)" | "f \<in> \<omega>(g)" | "f \<in> \<Omega>(g)" | "f \<in> \<Theta>(g)"
  ) = {* K (Landau.lift_landau_simproc Landau.simplify_landau_sum_simproc) *}
                                   
simproc_setup simplify_landau_product (
    "o(\<lambda>x. f x)" | "O(\<lambda>x. f x)" | "\<omega>(\<lambda>x. f x)" | "\<Omega>(\<lambda>x. f x)" | "\<Theta>(\<lambda>x. f x)" |
    "f \<in> o(g)" | "f \<in> O(g)" | "f \<in> \<omega>(g)" | "f \<in> \<Omega>(g)" | "f \<in> \<Theta>(g)"
  ) = {* K (Landau.lift_landau_simproc Landau.simplify_landau_product_simproc) *}

simproc_setup landau_real_prod (
    "(f :: real \<Rightarrow> real) \<in> o(g)" | "(f :: real \<Rightarrow> real) \<in> O(g)" |
    "(f :: real \<Rightarrow> real) \<in> \<omega>(g)" | "(f :: real \<Rightarrow> real) \<in> \<Omega>(g)" |
    "(f :: real \<Rightarrow> real) \<in> \<Theta>(g)"
  ) = {* K Landau.simplify_landau_real_prod_prop_simproc *}



subsection {* Tests *}

subsubsection {* Product simplification tests *}

lemma "(\<lambda>x::_::field. f x * x) \<in> O(\<lambda>x. g x / (h x / x)) \<longleftrightarrow> f \<in> O(\<lambda>x. g x / h x)"
  by simp

lemma "(\<lambda>x::_::field. x) \<in> \<omega>(\<lambda>x. g x / (h x / x)) \<longleftrightarrow> (\<lambda>x. 1) \<in> \<omega>(\<lambda>x. g x / h x)"
  by simp


subsubsection {* Real product decision procure tests *}

lemma "(\<lambda>x. x powr 1) \<in> O(\<lambda>x. x powr 2 :: real)"
  by simp

lemma "\<Theta>(\<lambda>x::real. 2*x powr 3 - 4*x powr 2) = \<Theta>(\<lambda>x::real. x powr 3)"
  by (simp add: landau_theta.absorb)

lemma "p < q \<Longrightarrow> (\<lambda>x::real. c * x powr p * ln x powr r) \<in> o(\<lambda>x::real. x powr q)"
  by simp

lemma "c \<noteq> 0 \<Longrightarrow> p > q \<Longrightarrow> (\<lambda>x::real. c * x powr p * ln x powr r) \<in> \<omega>(\<lambda>x::real. x powr q)"
  by simp

lemma "b > 0 \<Longrightarrow> (\<lambda>x::real. x / ln (2*b*x) * 2) \<in> o(\<lambda>x. x * ln (b*x))"
  by simp
lemma "o(\<lambda>x::real. x * ln (3*x)) = o(\<lambda>x. ln x * x)"
  by (simp add: mult.commute)
lemma "(\<lambda>x::real. x) \<in> o(\<lambda>x. x * ln (3*x))" by simp

ML_val {*
  Landau.simplify_landau_real_prod_prop_conv @{context} 
  @{cterm "(\<lambda>x::real. 5 * ln (ln x) ^ 2 / (2*x) powr 1.5 * inverse 2) \<in> 
           \<omega>(\<lambda>x. 3 * ln x * ln x / x * ln (ln (ln (ln x))))"}
*}

lemma "(\<lambda>x. 3 * ln x * ln x / x * ln (ln (ln (ln x)))) \<in> 
         \<omega>(\<lambda>x::real. 5 * ln (ln x) ^ 2 / (2*x) powr 1.5 * inverse 2)"
  by simp



subsubsection {* Sum cancelling tests *}

lemma "\<Theta>(\<lambda>x::real. 2 * x powr 3 + x * x^2/ln x) = \<Theta>(\<lambda>x::real. x powr 3)"
  by simp

(* TODO: tweak simproc with size threshold *)
lemma "\<Theta>(\<lambda>x::real. 2 * x powr 3 + x * x^2/ln x + 42 * x powr 9 + 213 * x powr 5 - 4 * x powr 7) = 
         \<Theta>(\<lambda>x::real. x ^ 3 + x / ln x * x powr (3/2) - 2*x powr 9)"
  by simp

lemma "(\<lambda>x::real. x + x * ln (3*x)) \<in> o(\<lambda>x::real. x^2 + ln (2*x) powr 3)" by simp


end