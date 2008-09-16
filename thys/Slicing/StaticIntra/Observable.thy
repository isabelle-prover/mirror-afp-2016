header {* \isaheader{Observable Sets of Nodes} *}

theory Observable imports Distance begin

inductive_set (in CFG) obs :: "'node \<Rightarrow> 'node set \<Rightarrow> 'node set" 
for n::"'node" and S::"'node set"
where obs_elem: 
  "\<lbrakk>n -as\<rightarrow>* n'; \<forall>nx \<in> set(sourcenodes as). nx \<notin> S; n' \<in> S\<rbrakk> \<Longrightarrow> n' \<in> obs n S"


lemma (in CFG) obsE:
  assumes "n' \<in> obs n S"
  obtains as where "n -as\<rightarrow>* n'" and "\<forall>nx \<in> set(sourcenodes as). nx \<notin> S"
  and "n' \<in> S"
proof -
  from `n' \<in> obs n S` 
  have "\<exists>as. n -as\<rightarrow>* n' \<and> (\<forall>nx \<in> set(sourcenodes as). nx \<notin> S) \<and> n' \<in> S"
    by(auto elim:obs.cases)
  with that show ?thesis by blast
qed


lemma (in CFG) n_in_obs:
  assumes "valid_node n" and "n \<in> S" shows "obs n S = {n}"
proof -
  from `valid_node n` have "n -[]\<rightarrow>* n" by(rule empty_path)
  with `n \<in> S` have "n \<in> obs n S" by(fastsimp elim:obs_elem simp:sourcenodes_def)
  { fix n' assume "n' \<in> obs n S"
    have "n' = n"
    proof(rule ccontr)
      assume "n' \<noteq> n"
      from `n' \<in> obs n S` obtain as where "n -as\<rightarrow>* n'"
	and "\<forall>nx \<in> set(sourcenodes as). nx \<notin> S"
	and "n' \<in> S" by(erule obsE)
      from `n -as\<rightarrow>* n'` `\<forall>nx \<in> set(sourcenodes as). nx \<notin> S` `n' \<noteq> n` `n \<in> S`
      show False
      proof(induct rule:path.induct)
	case (Cons_path n'' as n' a n)
	from `\<forall>nx\<in>set (sourcenodes (a#as)). nx \<notin> S` `sourcenode a = n`
	have "n \<notin> S" by(simp add:sourcenodes_def)
	with `n \<in> S` show False by simp
      qed simp
    qed }
  with `n \<in> obs n S` show ?thesis by fastsimp
qed


lemma (in CFG) in_obs_valid:
  "n' \<in> obs n S \<Longrightarrow> valid_node n \<and> valid_node n'"
by(induct rule:obs.induct,rule path_valid_node)


lemma (in CFG) edge_obs_subset:
  assumes"valid_edge a" and notin_S:"sourcenode a \<notin> S"
  shows "obs (targetnode a) S \<subseteq> obs (sourcenode a) S"
proof
  fix n assume "n \<in> obs (targetnode a) S"
  then obtain as where "targetnode a -as\<rightarrow>* n" 
    and all:"\<forall>nx \<in> set(sourcenodes as). nx \<notin> S" and "n \<in> S" by(erule obsE)
  from `valid_edge a` `targetnode a -as\<rightarrow>* n`
  have "sourcenode a -a#as\<rightarrow>* n" by(fastsimp intro:Cons_path)
  moreover
  from all `sourcenode a \<notin> S` have "\<forall>nx \<in> set(sourcenodes (a#as)). nx \<notin> S"
    by(simp add:sourcenodes_def)
  ultimately show "n \<in> obs (sourcenode a) S" using `n \<in> S`
    by(rule obs_elem)
qed


lemma (in CFG) path_obs_subset:
  "\<lbrakk>n -as\<rightarrow>* n'; \<forall>n' \<in> set(sourcenodes as). n' \<notin> S\<rbrakk>
  \<Longrightarrow> obs n' S \<subseteq> obs n S"
proof(induct rule:path.induct)
  case (Cons_path n'' as n' a n)
  note IH = `\<forall>n'\<in>set (sourcenodes as). n' \<notin> S \<Longrightarrow> obs n' S \<subseteq> obs n'' S`
  from `\<forall>n'\<in>set (sourcenodes (a#as)). n' \<notin> S` 
  have all:"\<forall>n'\<in>set (sourcenodes as). n' \<notin> S" and "sourcenode a \<notin> S"
    by(simp_all add:sourcenodes_def)
  from IH[OF all] have "obs n' S \<subseteq> obs n'' S" .
  from `valid_edge a` `targetnode a = n''` `sourcenode a = n` `sourcenode a \<notin> S`
  have "obs n'' S \<subseteq> obs n S" by(fastsimp dest:edge_obs_subset)
  with `obs n' S \<subseteq> obs n'' S` show ?case by fastsimp
qed simp


lemma (in CFG) path_ex_obs:
  assumes "n -as\<rightarrow>* n'" and "n' \<in> S"
  obtains m where "m \<in> obs n S"
proof -
  have "\<exists>m. m \<in> obs n S"
  proof(cases "\<forall>nx \<in> set(sourcenodes as). nx \<notin> S")
    case True
    with `n -as\<rightarrow>* n'` `n' \<in> S` have "n' \<in> obs n S" by -(rule obs_elem)
    thus ?thesis by fastsimp
  next
    case False
    hence "\<exists>nx \<in> set(sourcenodes as). nx \<in> S" by fastsimp
    then obtain nx ns ns' where "sourcenodes as = ns@nx#ns'"
      and "nx \<in> S" and "\<forall>n' \<in> set ns. n' \<notin> S"
      by(fastsimp elim!:leftmost_element_property)
    from `sourcenodes as = ns@nx#ns'` obtain as' a as'' 
      where "ns = sourcenodes as'"
      and "as = as'@a#as''" and "sourcenode a = nx"
      by(fastsimp elim:map_append_append_maps simp:sourcenodes_def)
    with `n -as\<rightarrow>* n'` have "n -as'\<rightarrow>* nx" by(fastsimp dest:path_split)
    with `nx \<in> S` `\<forall>n' \<in> set ns. n' \<notin> S` `ns = sourcenodes as'` have "nx \<in> obs n S"
      by(fastsimp intro:obs_elem)
    thus ?thesis by fastsimp
  qed
  with that show ?thesis by blast
qed


end

