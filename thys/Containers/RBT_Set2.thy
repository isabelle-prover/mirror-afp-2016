(*  Title:      Containers/RBT_Set2.thy
    Author:     Andreas Lochbihler, KIT *)

theory RBT_Set2 
imports
  RBT_Mapping2
  "~~/src/HOL/Library/Quotient_Set"
begin

section {* Sets implemented by red-black trees *}

lemma map_of_map_Pair_const:
  "map_of (map (\<lambda>x. (x, v)) xs) = (\<lambda>x. if x \<in> set xs then Some v else None)"
by(induct xs) auto

lemma map_of_rev_unit [simp]: 
  fixes xs :: "('a * unit) list" 
  shows "map_of (rev xs) = map_of xs"
by(induct xs rule: rev_induct)(auto simp add: map_add_def split: option.split)

lemma fold_split_conv_map_fst: "fold (\<lambda>(x, y). f x) xs = fold f (map fst xs)"
by(simp add: fold_map o_def split_def)

lemma foldr_split_conv_map_fst: "foldr (\<lambda>(x, y). f x) xs = foldr f (map fst xs)"
by(simp add: foldr_map o_def split_def fun_eq_iff)

lemma set_foldr_Cons:
  "set (foldr (\<lambda>x xs. if P x xs then x # xs else xs) as []) \<subseteq> set as"
by(induct as) auto

lemma distinct_fst_foldr_Cons:
  "distinct (map f as) \<Longrightarrow> distinct (map f (foldr (\<lambda>x xs. if P x xs then x # xs else xs) as []))"
proof(induct as)
  case (Cons a as)
  with set_foldr_Cons[of P as] show ?case by auto
qed simp

lemma filter_conv_foldr:
  "filter P xs = foldr (\<lambda>x xs. if P x then x # xs else xs) xs []"
by(induct xs) simp_all

lemma map_of_filter: "map_of (filter (\<lambda>x. P (fst x)) xs) = map_of xs |` Collect P"
by(induct xs)(simp_all add: fun_eq_iff restrict_map_def)

lemma map_of_map_Pair_key: "map_of (map (\<lambda>k. (k, f k)) xs) x = (if x \<in> set xs then Some (f x) else None)"
by(induct xs) simp_all

lemma neq_Empty_conv: "t \<noteq> rbt.Empty \<longleftrightarrow> (\<exists>c l k v r. t = Branch c l k v r)"
by(cases t) simp_all

context linorder begin

lemma is_rbt_RBT_fold_rbt_insert [simp]:
  "is_rbt t \<Longrightarrow> is_rbt (fold (\<lambda>(k, v). rbt_insert k v) xs t)"
by(induct xs arbitrary: t)(simp_all add: split_beta)

lemma rbt_lookup_RBT_fold_rbt_insert [simp]: 
  "is_rbt t \<Longrightarrow> rbt_lookup (fold (\<lambda>(k, v). rbt_insert k v) xs t) = rbt_lookup t ++ map_of (rev xs)"
apply(induct xs arbitrary: t rule: rev_induct)
apply(simp_all add: split_beta fun_eq_iff rbt_lookup_rbt_insert)
done

lemma is_rbt_fold_rbt_delete [simp]:
  "is_rbt t \<Longrightarrow> is_rbt (fold rbt_delete xs t)"
by(induct xs arbitrary: t)(simp_all)

lemma rbt_lookup_fold_rbt_delete [simp]: 
  "is_rbt t \<Longrightarrow> rbt_lookup (fold rbt_delete xs t) = rbt_lookup t |` (- set xs)"
apply(induct xs rule: rev_induct)
apply(simp_all add: rbt_lookup_rbt_delete ext)
apply(metis Un_insert_right compl_sup sup_bot_right)
done

lemma is_rbt_fold_rbt_insert: "is_rbt t \<Longrightarrow> is_rbt (fold (\<lambda>k. rbt_insert k (f k)) xs t)"
by(induct xs rule: rev_induct) simp_all

lemma rbt_lookup_fold_rbt_insert: 
  "is_rbt t \<Longrightarrow> 
  rbt_lookup (fold (\<lambda>k. rbt_insert k (f k)) xs t) = 
  rbt_lookup t ++ map_of (map (\<lambda>k. (k, f k)) xs)"
by(induct xs arbitrary: t)(auto simp add: rbt_lookup_rbt_insert map_add_def fun_eq_iff map_of_map_Pair_key split: option.splits)

end

definition fold_rev :: "('a \<Rightarrow> 'b \<Rightarrow> 'c \<Rightarrow> 'c) \<Rightarrow> ('a, 'b) rbt \<Rightarrow> 'c \<Rightarrow> 'c"
where "fold_rev f t = List.foldr (\<lambda>(k, v). f k v) (RBT_Impl.entries t)"

lemma fold_rev_simps [simp, code]:
  "fold_rev f RBT_Impl.Empty = id"
  "fold_rev f (Branch c l k v r) = fold_rev f l o f k v o fold_rev f r"
by(simp_all add: fold_rev_def fun_eq_iff)

definition (in ord) rbt_minus :: "('a, 'b) rbt \<Rightarrow> ('a, 'b) rbt \<Rightarrow> ('a, 'b) rbt"
where
  "rbt_minus t1 t2 =
  (let h1 = bheight t1; h2 = bheight t2
   in if 2 * h1 \<le> h2 then rbtreeify (fold_rev (\<lambda>k v kvs. if rbt_lookup t2 k = None then (k, v) # kvs else kvs) t1 [])
      else RBT_Impl.fold (\<lambda>k v. rbt_delete k) t2 t1)"

context linorder begin

lemma sorted_fst_foldr_Cons:
  "sorted (map f as) \<Longrightarrow> sorted (map f (foldr (\<lambda>x xs. if P x xs then x # xs else xs) as []))"
proof(induct as)
  case (Cons a as)
  with set_foldr_Cons[of P as] show ?case by(auto simp add: sorted_Cons)
qed simp

lemma is_rbt_rbt_minus:
  "\<lbrakk> is_rbt t1; is_rbt t2 \<rbrakk> \<Longrightarrow> is_rbt (rbt_minus t1 t2)"
by(auto simp add: rbt_minus_def Let_def RBT_Impl.fold_def fold_rev_def is_rbt_fold_rbt_delete[where xs="map fst (RBT_Impl.entries t2)", simplified fold_map o_def] split_def is_rbt_rbtreeify sorted_fst_foldr_Cons rbt_sorted_entries distinct_fst_foldr_Cons distinct_entries cong: if_cong)

lemma rbt_lookup_rbt_minus:
  "\<lbrakk> is_rbt t1; is_rbt t2 \<rbrakk> 
  \<Longrightarrow> rbt_lookup (rbt_minus t1 t2) = rbt_lookup t1 |` (- dom (rbt_lookup t2))"
apply(clarsimp simp add: rbt_minus_def Let_def domIff[symmetric] rbt_lookup_keys rbt_lookup_rbtreeify RBT_Impl.keys_def trans[OF RBT_Impl.fold_def fold_split_conv_map_fst] split_def sorted_fst_foldr_Cons rbt_sorted_entries distinct_fst_foldr_Cons distinct_entries fold_rev_def simp del: set_map cong: if_cong)
apply(auto simp add: map_of_entries[symmetric] filter_conv_foldr[symmetric] map_of_filter[where P="\<lambda>k. map_of (RBT_Impl.entries t2) k = None"] intro!: arg_cong[where f="\<lambda>x. map_of (RBT_Impl.entries t1) |` x"] dest: map_of_eq_None_iff[THEN iffD1] intro: map_of_eq_None_iff[THEN iffD2])
done

end

subsection {* Type and operations *}

type_synonym 'a set_rbt = "('a, unit) mapping_rbt"

translations 
  (type) "'a set_rbt" <= (type) "('a, unit) mapping_rbt"

abbreviation (input) Set_RBT :: "('a :: corder, unit) RBT_Impl.rbt \<Rightarrow> 'a set_rbt"
where "Set_RBT \<equiv> Mapping_RBT"

subsection {* Primitive operations *}

lift_definition member :: "'a :: corder set_rbt \<Rightarrow> 'a \<Rightarrow> bool" is
  "\<lambda>t x. x \<in> dom (ord.rbt_lookup cless t)"
by simp

abbreviation empty :: "'a :: corder set_rbt"
where "empty \<equiv> RBT_Mapping2.empty"

abbreviation insert :: "'a :: corder \<Rightarrow> 'a set_rbt \<Rightarrow> 'a set_rbt" 
where "insert k \<equiv> RBT_Mapping2.insert k ()"

abbreviation remove :: "'a :: corder \<Rightarrow> 'a set_rbt \<Rightarrow> 'a set_rbt"
where "remove \<equiv> RBT_Mapping2.delete"

lift_definition bulkload :: "'a :: corder list \<Rightarrow> 'a set_rbt" is
  "ord.rbt_bulkload cless \<circ> map (\<lambda>x. (x, ()))"
by(auto 4 3 intro: linorder.rbt_bulkload_is_rbt ID_corder)

abbreviation is_empty :: "'a :: corder set_rbt \<Rightarrow> bool"
where "is_empty \<equiv> RBT_Mapping2.is_empty"

abbreviation union :: "'a :: corder set_rbt \<Rightarrow> 'a set_rbt \<Rightarrow> 'a set_rbt"
where "union \<equiv> RBT_Mapping2.join (\<lambda>_ _. id)"

abbreviation inter :: "'a :: corder set_rbt \<Rightarrow> 'a set_rbt \<Rightarrow> 'a set_rbt"
where "inter \<equiv> RBT_Mapping2.meet (\<lambda>_ _. id)"

lift_definition inter_list :: "'a :: corder set_rbt \<Rightarrow> 'a list \<Rightarrow> 'a set_rbt" is
  "\<lambda>t xs. fold (\<lambda>k. ord.rbt_insert cless k ()) [x \<leftarrow> xs. ord.rbt_lookup cless t x \<noteq> None] RBT_Impl.Empty"
by(auto 4 3 intro: ID_corder linorder.is_rbt_fold_rbt_insert ord.Empty_is_rbt)

lift_definition minus :: "'a :: corder set_rbt \<Rightarrow> 'a set_rbt \<Rightarrow> 'a set_rbt" is 
  "ord.rbt_minus cless"
by(auto 4 3 intro: linorder.is_rbt_rbt_minus ID_corder)

abbreviation filter :: "('a :: corder \<Rightarrow> bool) \<Rightarrow> 'a set_rbt \<Rightarrow> 'a set_rbt"
where "filter P \<equiv> RBT_Mapping2.filter (P \<circ> fst)"

lift_definition fold :: "('a :: corder \<Rightarrow> 'b \<Rightarrow> 'b) \<Rightarrow> 'a set_rbt \<Rightarrow> 'b \<Rightarrow> 'b" is "\<lambda>f. RBT_Impl.fold (\<lambda>a _. f a)" ..

lift_definition fold1 :: "('a :: corder \<Rightarrow> 'a \<Rightarrow> 'a) \<Rightarrow> 'a set_rbt \<Rightarrow> 'a" is "RBT_Impl_fold1" ..

lift_definition keys :: "'a :: corder set_rbt \<Rightarrow> 'a list" is "RBT_Impl.keys" ..

abbreviation all :: "('a :: corder \<Rightarrow> bool) \<Rightarrow> 'a set_rbt \<Rightarrow> bool"
where "all P \<equiv> RBT_Mapping2.all (\<lambda>k _. P k)"

abbreviation ex :: "('a :: corder \<Rightarrow> bool) \<Rightarrow> 'a set_rbt \<Rightarrow> bool"
where "ex P \<equiv> RBT_Mapping2.ex (\<lambda>k _. P k)"

definition product :: "'a :: corder set_rbt \<Rightarrow> 'b :: corder set_rbt \<Rightarrow> ('a \<times> 'b) set_rbt"
where "product rbt1 rbt2 = RBT_Mapping2.product (\<lambda>_ _ _ _. ()) rbt1 rbt2"

abbreviation Id_on :: "'a :: corder set_rbt \<Rightarrow> ('a \<times> 'a) set_rbt"
where "Id_on \<equiv> RBT_Mapping2.diag"

abbreviation init :: "'a :: corder set_rbt \<Rightarrow> ('a, unit, 'a) rbt_generator_state"
where "init \<equiv> RBT_Mapping2.init"

subsection {* Properties *}

lemma member_empty [simp]:
  "member empty = (\<lambda>_. False)"
by(simp add: member_def empty_def Mapping_RBT_inverse ord.Empty_is_rbt ord.rbt_lookup.simps fun_eq_iff)

lemma fold_conv_fold_keys: "RBT_Set2.fold f rbt b = List.fold f (RBT_Set2.keys rbt) b"
by(simp add: RBT_Set2.fold_def RBT_Set2.keys_def RBT_Impl.fold_def RBT_Impl.keys_def fold_map o_def split_def)

lemma fold_conv_fold_keys':
  "fold f t = List.fold f (RBT_Impl.keys (RBT_Mapping2.impl_of t))"
by(simp add: fold.rep_eq RBT_Impl.fold_def RBT_Impl.keys_def fold_map o_def split_def)

lemma member_lookup [code]: "member t x \<longleftrightarrow> RBT_Mapping2.lookup t x = Some ()"
by transfer auto

lemma unfoldr_rbt_keys_generator:
  "list.unfoldr rbt_keys_generator (init t) = keys t"
by transfer(simp add: unfoldr_rbt_keys_generator)

context assumes ID_corder_neq_None: "ID CORDER('a :: corder) \<noteq> None"
begin

lemma set_linorder: "class.linorder (cless_eq :: 'a \<Rightarrow> 'a \<Rightarrow> bool) cless"
using ID_corder_neq_None by(clarsimp)(rule ID_corder)

lemma is_rbt_impl_of [simp, intro]:
  fixes t :: "'a set_rbt"
  shows "ord.is_rbt cless (RBT_Mapping2.impl_of t)"
  using ID_corder_neq_None impl_of [of t] by auto

lemma member_RBT:
  "ord.is_rbt cless t \<Longrightarrow> member (Set_RBT t) x \<longleftrightarrow> ord.rbt_lookup cless t x = Some ()"
by(auto simp add: member_def Mapping_RBT_inverse)

lemma member_impl_of:
  "ord.rbt_lookup cless (RBT_Mapping2.impl_of t) x = Some () \<longleftrightarrow> member t x"
by transfer auto

lemma member_insert [simp]:
  "member (insert x (t :: 'a set_rbt)) = (member t)(x := True)"
by transfer (simp add: fun_eq_iff linorder.rbt_lookup_rbt_insert[OF set_linorder] ID_corder_neq_None)

lemma member_fold_insert [simp]:
  "member (List.fold insert xs (t :: 'a set_rbt)) = (\<lambda>x. member t x \<or> x \<in> set xs)"
by(induct xs arbitrary: t) auto

lemma member_remove [simp]:
  "member (remove (x :: 'a) t) = (member t)(x := False)"
by transfer (simp add: linorder.rbt_lookup_rbt_delete[OF set_linorder] ID_corder_neq_None fun_eq_iff)

lemma member_bulkload [simp]:
  "member (bulkload xs) (x :: 'a) \<longleftrightarrow> x \<in> set xs"
by transfer (auto simp add: linorder.rbt_lookup_rbt_bulkload[OF set_linorder] map_of_map_Pair_const split: split_if_asm)

lemma member_conv_keys: "member t = (\<lambda>x :: 'a. x \<in> set (keys t))"
by(transfer)(simp add: ID_corder_neq_None linorder.rbt_lookup_keys[OF set_linorder] ord.is_rbt_rbt_sorted)

lemma is_empty_empty [simp]:
  "is_empty t \<longleftrightarrow> t = empty"
by transfer (simp split: rbt.split)

lemma RBT_lookup_empty [simp]:
  "ord.rbt_lookup cless (t :: ('a, unit) rbt) = Map.empty \<longleftrightarrow> t = RBT_Impl.Empty"
proof -
  interpret linorder "cless_eq :: 'a \<Rightarrow> 'a \<Rightarrow> bool" cless by(rule set_linorder)
  show ?thesis by(cases t)(auto simp add: fun_eq_iff)
qed

lemma member_empty_empty [simp]:
  "member t = (\<lambda>_. False) \<longleftrightarrow> (t :: 'a set_rbt) = empty"
by transfer(simp add: ID_corder_neq_None fun_eq_iff RBT_lookup_empty[symmetric])

lemma member_union [simp]:
  "member (union (t1 :: 'a set_rbt) t2) = (\<lambda>x. member t1 x \<or> member t2 x)"
by(auto simp add: member_lookup fun_eq_iff lookup_join[OF ID_corder_neq_None] split: option.split)

lemma member_minus [simp]:
  "member (minus (t1 :: 'a set_rbt) t2) = (\<lambda>x. member t1 x \<and> \<not> member t2 x)"
by(transfer)(auto simp add: ID_corder_neq_None fun_eq_iff linorder.rbt_lookup_rbt_minus[OF set_linorder] ord.is_rbt_rbt_sorted)

lemma member_inter [simp]:
  "member (inter (t1 :: 'a set_rbt) t2) = (\<lambda>x. member t1 x \<and> member t2 x)"
by(auto simp add: member_lookup fun_eq_iff lookup_meet[OF ID_corder_neq_None] split: option.split)

lemma member_inter_list [simp]:
  "member (inter_list (t :: 'a set_rbt) xs) = (\<lambda>x. member t x \<and> x \<in> set xs)"
by transfer(auto simp add: ID_corder_neq_None fun_eq_iff linorder.rbt_lookup_fold_rbt_insert[OF set_linorder] ord.Empty_is_rbt map_of_map_Pair_key ord.rbt_lookup.simps option_rel_unfold split: split_if_asm option.split_asm)

lemma member_filter [simp]:
  "member (filter P (t :: 'a set_rbt)) = (\<lambda>x. member t x \<and> P x)"
by(simp add: member_lookup fun_eq_iff lookup_filter[OF ID_corder_neq_None] split: option.split)

lemma distinct_keys [simp]:
  "distinct (keys (rbt :: 'a set_rbt))"
by transfer(simp add: ID_corder_neq_None RBT_Impl.keys_def ord.is_rbt_rbt_sorted linorder.distinct_entries[OF set_linorder])

lemma all_conv_all_member:
  "all P t \<longleftrightarrow> (\<forall>x :: 'a. member t x \<longrightarrow> P x)"
by(simp add: member_lookup all_conv_all_lookup[OF ID_corder_neq_None])

lemma ex_conv_ex_member:
  "ex P t \<longleftrightarrow> (\<exists>x :: 'a. member t x \<and> P x)"
by(simp add: member_lookup ex_conv_ex_lookup[OF ID_corder_neq_None])

lemma finite_member: "finite (Collect (RBT_Set2.member (t :: 'a set_rbt)))"
by transfer (simp add: linorder.finite_dom_rbt_lookup[OF set_linorder])

lemma member_Id_on: "member (Id_on t) = (\<lambda>(k :: 'a, k'). k = k' \<and> member t k)"
by(simp add: member_lookup[abs_def] diag_lookup[OF ID_corder_neq_None] fun_eq_iff)

context assumes ID_corder_neq_None': "ID CORDER('b :: corder) \<noteq> None"
begin

lemma set_linorder': "class.linorder (cless_eq :: 'b \<Rightarrow> 'b \<Rightarrow> bool) cless"
using ID_corder_neq_None' by(clarsimp)(rule ID_corder)

lemma member_product:
  "member (product rbt1 rbt2) = (\<lambda>ab :: 'a \<times> 'b. ab \<in> Collect (member rbt1) \<times> Collect (member rbt2))"
by(auto simp add: fun_eq_iff member_lookup product_def RBT_Mapping2.lookup_product ID_corder_neq_None ID_corder_neq_None' split: option.splits)

end

end

lemma sorted_RBT_Set_keys: 
  "Option.map fst (ID CORDER('a :: corder)) = Some le 
  \<Longrightarrow> linorder.sorted le (RBT_Set2.keys rbt)"
by transfer(auto simp add: RBT_Set2.keys.rep_eq RBT_Impl.keys_def linorder.rbt_sorted_entries[OF ID_corder] ord.is_rbt_rbt_sorted)

context assumes ID_corder_neq_None: "ID CORDER('a :: {corder, lattice}) \<noteq> None"
begin

lemma set_linorder2: "class.linorder (cless_eq :: 'a \<Rightarrow> 'a \<Rightarrow> bool) cless"
using ID_corder_neq_None by(clarsimp)(rule ID_corder)

lemma Inf_fin_member:
  "(rbt :: 'a set_rbt) \<noteq> RBT_Set2.empty \<Longrightarrow> Inf_fin (Collect (member rbt)) = RBT_Set2.fold1 inf rbt"
by(transfer)(clarsimp simp add: ID_corder_neq_None linorder.rbt_lookup_keys[OF set_linorder2] ord.is_rbt_rbt_sorted RBT_Impl_fold1_def neq_Empty_conv, simp add: Inf_fin_set_fold[symmetric])

lemma Sup_fin_member:
  "(rbt :: 'a set_rbt) \<noteq> RBT_Set2.empty \<Longrightarrow> Sup_fin (Collect (member rbt)) = RBT_Set2.fold1 sup rbt"
by(transfer)(clarsimp simp add: ID_corder_neq_None linorder.rbt_lookup_keys[OF set_linorder2] ord.is_rbt_rbt_sorted RBT_Impl_fold1_def neq_Empty_conv, simp add: Sup_fin_set_fold[symmetric])

end

hide_const (open) member empty insert remove bulkload union keys fold fold_rev filter all ex product Id_on init

end