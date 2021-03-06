section {* Uniform Strategies *}

text {* Theorems about how to get a uniform strategy given strategies for each node. *}

theory UniformStrategy
imports
  Main
  AttractingStrategy WinningStrategy WellOrderedStrategy WinningRegion
begin

context ParityGame begin

subsection {* A Uniform Attractor Strategy *}

lemma merge_attractor_strategies:
  assumes "S \<subseteq> V"
    and strategies_ex: "\<And>v. v \<in> S \<Longrightarrow> \<exists>\<sigma>. strategy p \<sigma> \<and> strategy_attracts_via p \<sigma> v S W"
  shows "\<exists>\<sigma>. strategy p \<sigma> \<and> strategy_attracts p \<sigma> S W"
proof-
  def good \<equiv> "\<lambda>v. { \<sigma>. strategy p \<sigma> \<and> strategy_attracts_via p \<sigma> v S W }"
  let ?G = "{\<sigma>. \<exists>v \<in> S - W. \<sigma> \<in> good v}"
  obtain r where r: "well_order_on ?G r" using well_order_on by blast

  interpret WellOrderedStrategies G "S - W" p good r proof
    show "S - W \<subseteq> V" using `S \<subseteq> V` by blast
  next
    show "\<And>v. v \<in> S - W \<Longrightarrow> \<exists>\<sigma>. \<sigma> \<in> good v" unfolding good_def using strategies_ex by blast
  next
    show "\<And>v \<sigma>. \<sigma> \<in> good v \<Longrightarrow> strategy p \<sigma>" unfolding good_def by blast
  next
    fix v w \<sigma> assume v: "v \<in> S - W" "v\<rightarrow>w" "v \<in> VV p \<Longrightarrow> \<sigma> v = w" "\<sigma> \<in> good v"
    hence \<sigma>: "strategy p \<sigma>" "strategy_attracts_via p \<sigma> v S W" unfolding good_def by simp_all
    hence "strategy_attracts_via p \<sigma> w S W" using strategy_attracts_via_successor v by blast
    thus "\<sigma> \<in> good w" unfolding good_def using \<sigma>(1) by blast
  qed (insert r)

  have S_W_no_deadends: "\<And>v. v \<in> S - W \<Longrightarrow> \<not>deadend v"
    using strategy_attracts_via_no_deadends[of _ S W] strategies_ex
    by (metis (no_types) Diff_iff S_V rev_subsetD)

  {
    fix v0 assume "v0 \<in> S"
    fix P assume P: "vmc_path G P v0 p well_ordered_strategy"
    then interpret vmc_path G P v0 p well_ordered_strategy .
    have "visits_via P S W" proof (rule ccontr)
      assume contra: "\<not>visits_via P S W"

      hence "lset P \<subseteq> S - W" proof (induct rule: vmc_path_lset_induction)
        case base
        show "v0 \<in> S - W" using `v0 \<in> S` contra visits_via_trivial by blast
      next
        case (step P v0)
        interpret vmc_path_no_deadend G P v0 p well_ordered_strategy using step.hyps(1) .
        have "insert v0 S = S" using step.hyps(2) by blast
        hence "\<not>visits_via (ltl P) S W"
          using visits_via_LCons[of "ltl P" S W v0, folded P_LCons] step.hyps(3) by auto
        moreover hence "w0 \<notin> W" using vmc_path.visits_via_trivial[OF vmc_path_ltl] by blast
        moreover have "w0 \<in> S \<union> W" proof (cases)
          assume "v0 \<in> VV p"
          hence "well_ordered_strategy v0 = w0" using v0_conforms by blast
          hence "choose v0 v0 = w0" using step.hyps(2) well_ordered_strategy_def by auto
          moreover have "strategy_attracts_via p (choose v0) v0 S W"
            using choose_good good_def step.hyps(2) by blast
          ultimately show ?thesis
            by (metis strategy_attracts_via_successor strategy_attracts_via_v0
                      choose_strategy step.hyps(2) `v0\<rightarrow>w0` w0_V)
        qed (metis DiffD1 assms(2) step.hyps(2) strategy_attracts_via_successor
                   strategy_attracts_via_v0 `v0\<rightarrow>w0` w0_V)
        ultimately show ?case by blast
      qed

      have "\<not>lfinite P" proof
        assume "lfinite P"
        hence "deadend (llast P)" using P_maximal `\<not>lnull P` maximal_ends_on_deadend by blast
        moreover have "llast P \<in> S - W" using `lset P \<subseteq> S - W` `\<not>lnull P` `lfinite P` lfinite_lset by blast
        ultimately show False using S_W_no_deadends by blast
      qed

      obtain n where n: "path_conforms_with_strategy p (ldropn n P) (path_strategies P $ n)"
        using path_eventually_conforms_to_\<sigma>_map_n[OF `lset P \<subseteq> S - W` P_valid P_conforms]
          by blast
      def [simp]: \<sigma>' \<equiv> "path_strategies P $ n"
      def [simp]: P' \<equiv> "ldropn n P"
      interpret vmc_path G P' "lhd P'" p \<sigma>' proof
        show "\<not>lnull P'" unfolding P'_def
          using `\<not>lfinite P` lfinite_ldropn lnull_imp_lfinite by blast
      qed (simp_all add: n)
      have "strategy p \<sigma>'" unfolding \<sigma>'_def
        using path_strategies_strategy `lset P \<subseteq> S - W` `\<not>lfinite P` infinite_small_llength
        by blast
      moreover have "strategy_attracts_via p \<sigma>' (lhd P') S W" proof-
        have "P $ n \<in> S - W" using `lset P \<subseteq> S - W` `\<not>lfinite P` lset_nth_member_inf by blast
        hence "\<sigma>' \<in> good (P $ n)"
          using path_strategies_good \<sigma>'_def `\<not>lfinite P` `lset P \<subseteq> S - W` by blast
        hence "strategy_attracts_via p \<sigma>' (P $ n) S W" unfolding good_def by blast
        thus ?thesis unfolding P'_def using P_0 by (simp add: `\<not>lfinite P` infinite_small_llength)
      qed
      moreover from `lset P \<subseteq> S - W` have "lset P' \<subseteq> S - W"
        unfolding P'_def using lset_ldropn_subset[of n P] by blast
      ultimately show False using strategy_attracts_via_lset by blast
    qed
  }
  thus ?thesis using well_ordered_strategy_valid by blast
qed


subsection {* A Uniform Winning Strategy *}

text {*
  Let @{term S} be the winning region of player @{term p}.
  Then there exists a uniform winning strategy on @{term S}.
*}

lemma merge_winning_strategies:
  shows "\<exists>\<sigma>. strategy p \<sigma> \<and> (\<forall>v \<in> winning_region p. winning_strategy p \<sigma> v)"
proof-
  def good \<equiv> "\<lambda>v. { \<sigma>. strategy p \<sigma> \<and> winning_strategy p \<sigma> v }"
  let ?G = "{\<sigma>. \<exists>v \<in> winning_region p. \<sigma> \<in> good v}"
  obtain r where r: "well_order_on ?G r" using well_order_on by blast

  have no_VVp_deadends: "\<And>v. \<lbrakk> v \<in> winning_region p; v \<in> VV p \<rbrakk> \<Longrightarrow> \<not>deadend v"
    using no_winning_strategy_on_deadends unfolding winning_region_def by blast

  interpret WellOrderedStrategies G "winning_region p" p good r proof
    show "\<And>v. v \<in> winning_region p \<Longrightarrow> \<exists>\<sigma>. \<sigma> \<in> good v"
      unfolding good_def winning_region_def by blast
  next
    show "\<And>v \<sigma>. \<sigma> \<in> good v \<Longrightarrow> strategy p \<sigma>" unfolding good_def by blast
  next
    fix v w \<sigma> assume v: "v \<in> winning_region p" "v\<rightarrow>w" "v \<in> VV p \<Longrightarrow> \<sigma> v = w" "\<sigma> \<in> good v"
    hence \<sigma>: "strategy p \<sigma>" "winning_strategy p \<sigma> v" unfolding good_def by simp_all
    hence "winning_strategy p \<sigma> w" proof (cases)
      assume "v \<in> VV p"
      moreover hence "\<sigma> v = w" using v(3) by blast
      moreover have "\<not>deadend v" using no_VVp_deadends `v \<in> VV p` v(1) by blast
      ultimately show ?thesis using strategy_extends_VVp \<sigma> by blast
    next
      assume "v \<notin> VV p"
      thus ?thesis using strategy_extends_VVpstar \<sigma> `v\<rightarrow>w` by blast
    qed
    thus "\<sigma> \<in> good w" unfolding good_def using \<sigma>(1) by blast
  qed (insert winning_region_in_V r)

  {
    fix v0 assume "v0 \<in> winning_region p"
    fix P assume P: "vmc_path G P v0 p well_ordered_strategy"
    then interpret vmc_path G P v0 p well_ordered_strategy .

    have "lset P \<subseteq> winning_region p" proof (induct rule: vmc_path_lset_induction_simple)
      case (step P v0)
      interpret vmc_path_no_deadend G P v0 p well_ordered_strategy using step.hyps(1) .
      { assume "v0 \<in> VV p"
        hence "well_ordered_strategy v0 = w0" using v0_conforms by blast
        hence "choose v0 v0 = w0" by (simp add: step.hyps(2) well_ordered_strategy_def)
      }
      hence "choose v0 \<in> good w0" using strategies_continue choose_good step.hyps(2) by simp
      thus ?case unfolding good_def winning_region_def using `w0 \<in> V` by blast
    qed (insert `v0 \<in> winning_region p`)

    have "winning_path p P" proof (rule ccontr)
      assume contra: "\<not>winning_path p P"

      have "\<not>lfinite P" proof
        assume "lfinite P"
        hence "deadend (llast P)" using maximal_ends_on_deadend by simp
        moreover have "llast P \<in> winning_region p"
          using `lset P \<subseteq> winning_region p` `\<not>lnull P` `lfinite P` lfinite_lset by blast
        moreover have "llast P \<in> VV p"
          using contra paths_are_winning_for_one_player `lfinite P`
          unfolding winning_path_def by simp
        ultimately show False using no_VVp_deadends by blast
      qed

      obtain n where n: "path_conforms_with_strategy p (ldropn n P) (path_strategies P $ n)"
        using path_eventually_conforms_to_\<sigma>_map_n[OF `lset P \<subseteq> winning_region p` P_valid P_conforms] by blast
      def [simp]: \<sigma>' \<equiv> "path_strategies P $ n"
      def [simp]: P' \<equiv> "ldropn n P"
      interpret P': vmc_path G P' "lhd P'" p \<sigma>' proof
        show "\<not>lnull P'" using `\<not>lfinite P` unfolding P'_def
          using lfinite_ldropn lnull_imp_lfinite by blast
      qed (simp_all add: n)
      have "strategy p \<sigma>'" unfolding \<sigma>'_def
        using path_strategies_strategy `lset P \<subseteq> winning_region p` `\<not>lfinite P` by blast
      moreover have "winning_strategy p \<sigma>' (lhd P')" proof-
        have "P $ n \<in> winning_region p"
          using `lset P \<subseteq> winning_region p` `\<not>lfinite P` lset_nth_member_inf by blast
        hence "\<sigma>' \<in> good (P $ n)"
          using path_strategies_good choose_good \<sigma>'_def `\<not>lfinite P` `lset P \<subseteq> winning_region p`
          by blast
        hence "winning_strategy p \<sigma>' (P $ n)" unfolding good_def by blast
        thus ?thesis
          unfolding P'_def using P_0 `\<not>lfinite P` by (simp add: infinite_small_llength lhd_ldropn)
      qed
      ultimately have "winning_path p P'" unfolding winning_strategy_def
        using P'.vmc_path_axioms by blast
      moreover have "\<not>lfinite P'" using `\<not>lfinite P` P'_def by simp
      ultimately show False using contra winning_path_drop_add[OF P_valid] by auto
    qed
  }
  thus ?thesis unfolding winning_strategy_def using well_ordered_strategy_valid by auto
qed

subsection {* Extending Winning Regions *}

text {*
  Now we are finally able to prove the complement of @{text winning_region_extends_VVp} for
  @{term "VV p**"} nodes, which was still missing.
*}

lemma winning_region_extends_VVpstar:
  assumes v: "v \<in> VV p**" and w: "\<And>w. v\<rightarrow>w \<Longrightarrow> w \<in> winning_region p"
  shows "v \<in> winning_region p"
proof-
  obtain \<sigma> where \<sigma>: "strategy p \<sigma>"  "\<And>v. v \<in> winning_region p \<Longrightarrow> winning_strategy p \<sigma> v"
    using merge_winning_strategies by blast
  have "winning_strategy p \<sigma> v" using strategy_extends_backwards_VVpstar[OF v \<sigma>(1)] \<sigma>(2) w by blast
  thus ?thesis unfolding winning_region_def using v \<sigma>(1) by blast
qed

text {* It immediately follows that removing a winning region cannot create new deadends. *}

lemma removing_winning_region_induces_no_deadends:
  assumes "v \<in> V - winning_region p" "\<not>deadend v"
  shows "\<exists>w \<in> V - winning_region p. v\<rightarrow>w"
  using assms winning_region_extends_VVp winning_region_extends_VVpstar by blast

end -- "context ParityGame"

end
