# Current complete-record NHANES analysis. Run from RStudio with source(..., encoding='UTF-8').
run_analysis <- function(root = getwd()) {
  if (.Platform$OS.type == 'windows') Sys.setlocale('LC_CTYPE','English_United States.utf8')
  stopifnot(requireNamespace('haven',quietly=TRUE),requireNamespace('survey',quietly=TRUE))
  options(survey.lonely.psu='fail')
  res <- file.path(root,'results'); fig <- file.path(res,'figures')
  for (p in c(res,fig,file.path(root,'data/interim'),file.path(root,'data/final'))) dir.create(p,recursive=TRUE,showWarnings=FALSE)
  csv <- function(x,name) write.csv(x,file.path(res,name),row.names=FALSE,fileEncoding='UTF-8')
  paths <- file.path(root,'data/raw',paste0(c('DEMO','BPXO','BMX','BPQ'),'_L.xpt'))
  hashes <- tools::md5sum(paths)
  raw <- lapply(paths,haven::read_xpt)
  for (r in raw) stopifnot(!anyNA(r$SEQN),!anyDuplicated(r$SEQN))
  select <- list(c('SEQN','RIDSTATR','RIDAGEYR','RIAGENDR','RIDRETH3','DMDEDUC2','INDFMPIR','RIDEXPRG','WTINT2YR','WTMEC2YR','SDMVSTRA','SDMVPSU'),
   c('BPXOSY1','BPXOSY2','BPXOSY3','BPXODI1','BPXODI2','BPXODI3'),
   c('BMDSTATS','BMXWT','BMXHT','BMXBMI','BMXWAIST'),c('BPQ020','BPQ030','BPQ150'))
  d <- as.data.frame(raw[[1]][select[[1]]])
  for (j in 2:4) {
    at <- match(d$SEQN,raw[[j]]$SEQN)
    for(v in select[[j]]) d[[v]] <- as.numeric(raw[[j]][[v]][at])
    d[[c('has_bpxo','has_bmx','has_bpq')[j-1]]] <- !is.na(at)
  }
  stopifnot(nrow(d)==11933,ncol(d)==29,!anyDuplicated(d$SEQN))
  write.csv(d,file.path(root,'data/interim/nhanes_merged_29.csv'),row.names=FALSE)
  saveRDS(d,file.path(root,'data/interim/nhanes_merged_29.rds'))
  # Preserve valid SBP when a DBP reading is absent; invalidate impossible paired values.
  s <- sapply(1:3,function(j) {
    a<-d[[paste0('BPXOSY',j)]]; b<-d[[paste0('BPXODI',j)]]
    bad<-!is.na(a)&(!is.finite(a)|a<=0|a>300)
    pair<-!is.na(a)&!is.na(b)&a<=b
    a[bad|pair]<-NA_real_;a
  })
  d$sbp_n<-rowSums(!is.na(s));d$sbp<-rowMeans(s,na.rm=TRUE);d$sbp[d$sbp_n<2]<-NA_real_
  d$pir<-as.numeric(d$INDFMPIR);d$bmi<-as.numeric(d$BMXBMI);d$bmi[!is.finite(d$bmi)|d$bmi<=0]<-NA_real_
  d$education_code<-as.numeric(d$DMDEDUC2);d$education_code[!d$education_code%in%1:5]<-NA_real_
  pregnancy<-rep('outside_public_release_scope',nrow(d))
  scope<-d$RIAGENDR==2 & d$RIDAGEYR>=20 & d$RIDAGEYR<=44
  pregnancy[scope]<-'missing_in_scope'
  known<-scope & !is.na(d$RIDEXPRG)
  pregnancy[known]<-c('pregnant','not_pregnant','undetermined')[d$RIDEXPRG[known]]
  d$pregnancy_status<-pregnancy
  d$valid_mec<-is.finite(d$WTMEC2YR)&d$WTMEC2YR>0&!is.na(d$SDMVSTRA)&!is.na(d$SDMVPSU)
  mec<-d$valid_mec;adult<-mec&d$RIDAGEYR>=20;bp<-adult&!is.na(d$sbp)
  eligible<-bp&pregnancy!='pregnant';income<-eligible&!is.na(d$pir);bmi<-income&!is.na(d$bmi)
  fields<-c('sbp','pir','RIDAGEYR','RIAGENDR','RIDRETH3','bmi','education_code','WTMEC2YR','SDMVSTRA','SDMVPSU')
  cc<-bmi&complete.cases(d[fields]);stopifnot(sum(cc)==5019)
  final<-data.frame(SEQN=d$SEQN[cc],sbp=d$sbp[cc],pir=d$pir[cc],age=d$RIDAGEYR[cc],sex=d$RIAGENDR[cc],race=d$RIDRETH3[cc],bmi=d$bmi[cc],education=d$education_code[cc],weight_mec=d$WTMEC2YR[cc],stratum=d$SDMVSTRA[cc],psu=d$SDMVPSU[cc])
  stopifnot(!anyNA(final),!anyDuplicated(final$SEQN))
  finalcsv<-file.path(root,'data/final/nhanes_complete_5019.csv')
  finalxpt<-file.path(root,'data/final/nhanes_complete_5019.xpt')
  write.csv(final,finalcsv,row.names=FALSE,fileEncoding='UTF-8')
  haven::write_xpt(final,finalxpt,version=8,name='NHANES_CC')
  reread<-as.data.frame(haven::read_xpt(finalxpt))
  stopifnot(isTRUE(all.equal(final,reread,check.attributes=FALSE)),isTRUE(all.equal(final,read.csv(finalcsv),check.attributes=FALSE)))
  flow<-data.frame(step=c('\u8fde\u63a5\u8868','\u6709\u6548\u4f53\u68c0\u4e0e\u8bbe\u8ba1\u4fe1\u606f','\u5e74\u9f84\u81f3\u5c1120\u5c81','\u81f3\u5c11\u4e24\u6b21\u6709\u6548\u6536\u7f29\u538b','\u6392\u9664\u5df2\u77e5\u598a\u5a20','\u6536\u5165\u5b8c\u6574','BMI\u5b8c\u6574','\u6559\u80b2\u53ca\u6240\u6709\u6a21\u578b\u5b57\u6bb5\u5b8c\u6574'),n=c(nrow(d),sum(mec),sum(adult),sum(bp),sum(eligible),sum(income),sum(bmi),sum(cc)))
  flow$removed<-c(0,-diff(flow$n));csv(flow,'sample_flow.csv')
  csv(data.frame(variable=names(final),missing=colSums(is.na(final))),'final_missingness.csv')
  # Full valid-MEC survey design, then domains: preserve all 15 strata and 30 PSUs.
  d$age_c<-d$RIDAGEYR-50;d$age_c2<-d$age_c^2;d$bmi_c<-d$bmi-30
  d$sex<-factor(d$RIAGENDR,levels=c(1,2));d$race<-factor(d$RIDRETH3,levels=c(3,1,2,4,6,7))
  d$education<-factor(d$education_code,levels=c(3,1,2,4,5))
  ns<-splines::ns(d$RIDAGEYR,knots=c(40,60),Boundary.knots=c(20,80))
  for(j in 1:3)d[[paste0('age_s',j)]]<-ns[,j]
  d$eligible<-eligible;d$cc<-cc
  d$income_group<-factor(ifelse(d$pir<1,'<1',ifelse(d$pir<2,'1\u2013<2',ifelse(d$pir<3,'2\u2013<3',ifelse(d$pir<5,'3\u2013<5','\u22655')))),levels=c('<1','1\u2013<2','2\u2013<3','3\u2013<5','\u22655'))
  d$white<-as.numeric(d$RIDRETH3==3);d$black<-as.numeric(d$RIDRETH3==4);d$female<-as.numeric(d$RIAGENDR==2)
  d$college<-ifelse(is.na(d$education_code),NA_real_,as.numeric(d$education_code==5))
  design<-survey::svydesign(ids=~SDMVPSU,strata=~SDMVSTRA,weights=~WTMEC2YR,nest=TRUE,data=d[mec,])
  ds<-subset(design,cc);saveRDS(design,file.path(root,'data/interim/design_full_mec.rds'))
  forms<-list(M1=sbp~pir+age_c+sex+race,M2=sbp~pir+age_c+sex+race+bmi_c,M3=sbp~pir+age_c+sex+race+bmi_c+education)
  models<-lapply(forms,function(f)survey::svyglm(f,design=ds,family=gaussian()))
  extract<-function(fit,label,setting='\u7ebf\u6027\u5e74\u9f84') {
    s<-coef(summary(fit));df<-fit$df.residual;z<-qt(.975,df)
    data.frame(model=label,setting=setting,term=rownames(s),estimate=s[,1],se=s[,2],lower=s[,1]-z*s[,2],upper=s[,1]+z*s[,2],p=s[,4],df=df,n=nrow(fit$model),row.names=NULL)
  }
  all<-do.call(rbind,lapply(names(models),function(n)extract(models[[n]],n)));csv(all,'model_coefficients.csv');csv(all[all$term=='pir',],'income_results.csv')
  saveRDS(models,file.path(res,'models.rds'))
  # Descriptive summaries with variable-specific observed denominators.
  summarize<-function(domain,label,vars=c('RIDAGEYR','sbp','pir','bmi','female','white','black','college')) {
    z<-subset(design,domain);do.call(rbind,lapply(vars,function(v){
      ok<-!is.na(z$variables[[v]]);nv<-sum(ok)
      if(!nv)return(data.frame(group=label,variable=v,n_observed=0,estimate=NA,se=NA,lower=NA,upper=NA))
      zz<-z[ok,];m<-survey::svymean(as.formula(paste0('~',v)),zz);val<-as.numeric(coef(m));se<-as.numeric(survey::SE(m));df<-survey::degf(zz);k<-if(df>0)qt(.975,df) else NA_real_
      data.frame(group=label,variable=v,n_observed=nv,estimate=val,se=se,lower=val-k*se,upper=val+k*se)
    }))
  }
  descriptive<-summarize(d$cc[mec],'\u7eb3\u5165');csv(descriptive,'descriptive.csv')
  groups<-list('\u7eb3\u5165'=cc,'\u6536\u5165\u7f3a\u5931'=eligible&is.na(d$pir),'\u6536\u5165\u6709\u503c\u4f46BMI\u7f3a\u5931'=eligible&!is.na(d$pir)&is.na(d$bmi),'\u4ec5\u6559\u80b2\u7b49\u5b57\u6bb5\u7f3a\u5931'=bmi&!cc)
  comparison<-do.call(rbind,lapply(names(groups),function(n)summarize(groups[[n]][mec],n)))
  csv(comparison,'missing_group_comparison.csv')
  groupstats<-do.call(rbind,lapply(levels(d$income_group),function(g){
    mask<-ds$variables$income_group==g;z<-ds[mask,];m<-survey::svymean(~sbp,z)
    val<-as.numeric(coef(m));se<-as.numeric(survey::SE(m));k<-qt(.975,survey::degf(z))
    data.frame(group=g,n=nrow(z$variables),sbp=val,se=se,lower=val-k*se,upper=val+k*se)
  }));csv(groupstats,'income_group_descriptive.csv')
  # Age-form checks reuse the same records and adjustment variables.
  agefits<-list();for(n in c('M1','M2')) {
    q<-survey::svyglm(update(forms[[n]],.~.+age_c2),design=ds)
    f<-as.formula(gsub('age_c','age_s1+age_s2+age_s3',paste(deparse(forms[[n]]),collapse='')))
    sfit<-survey::svyglm(f,design=ds)
    agefits[[paste0(n,'q')]]<-extract(q,n,'\u5e74\u9f84\u4e8c\u6b21\u9879');agefits[[paste0(n,'s')]]<-extract(sfit,n,'\u5e74\u9f84\u81ea\u7136\u6837\u6761')
  }
  ageout<-rbind(all,do.call(rbind,agefits));csv(ageout[ageout$term=='pir',],'age_form_checks.csv')
  # Weighted design-matrix GVIF: geometric collinearity, separate from design-based SE.
  gvif<-function(fit){X<-model.matrix(fit);ass<-attr(X,'assign');w<-weights(ds);V<-solve(crossprod(X,w*X));R<-cov2cor(V[-1,-1]);ass<-ass[-1];labs<-attr(terms(fit),'term.labels')
    do.call(rbind,lapply(seq_along(labs),function(j){at<-which(ass==j);other<-setdiff(seq_len(ncol(R)),at)
      detsafe<-function(A)if(!length(A))1 else det(A)
      val<-detsafe(R[at,at,drop=FALSE])*detsafe(R[other,other,drop=FALSE])/det(R)
      data.frame(term=labs[j],df=length(at),GVIF=val,adjusted=val^(1/(2*length(at))))}))}
  vifs<-do.call(rbind,lapply(names(models),function(n)cbind(model=n,gvif(models[[n]]))));csv(vifs,'collinearity.csv')
  # Influence: delete an entire stratum (both PSUs), retaining a valid design each time.
  influence<-do.call(rbind,lapply(sort(unique(ds$variables$SDMVSTRA)),function(st){
    dd<-subset(design,SDMVSTRA!=st);zz<-subset(dd,cc)
    do.call(rbind,lapply(names(forms),function(n){f<-survey::svyglm(forms[[n]],design=zz);data.frame(model=n,omitted_stratum=st,estimate=coef(f)['pir'])}))
  }));csv(influence,'stratum_influence.csv')
  diagnostics<-do.call(rbind,lapply(names(models),function(n){f<-models[[n]];e<-residuals(f,type='response');w<-weights(ds);r2<-1-sum(w*e^2)/sum(w*(ds$variables$sbp-weighted.mean(ds$variables$sbp,w))^2)
    data.frame(model=n,n=nrow(ds$variables),design_df=survey::degf(ds),residual_df=f$df.residual,weighted_R2=r2,weighted_RMSE=sqrt(weighted.mean(e^2,w)),residual_skew=weighted.mean((e-weighted.mean(e,w))^3,w)/weighted.mean((e-weighted.mean(e,w))^2,w)^1.5)
  }));csv(diagnostics,'diagnostics.csv')
  # Standardized adjusted means across the observed covariate distribution.
  curves<-do.call(rbind,lapply(names(models),function(n){f<-models[[n]];do.call(rbind,lapply(seq(0,5,.25),function(p){nd<-ds$variables;nd$pir<-p
    X<-model.matrix(delete.response(terms(f)),nd,contrasts.arg=f$contrasts);xbar<-colSums(X*weights(ds))/sum(weights(ds));est<-sum(xbar*coef(f));se<-sqrt(as.numeric(t(xbar)%*%vcov(f)%*%xbar));k<-qt(.975,f$df.residual)
    data.frame(model=n,pir=p,sbp=est,lower=est-k*se,upper=est+k*se)
  }))}));csv(curves,'adjusted_curves.csv')
  csv(data.frame(file=basename(paths),md5=unname(hashes)),'raw_hashes.csv')
  for(fit in models){X<-model.matrix(fit);w<-weights(ds);b<-solve(crossprod(X,w*X),crossprod(X,w*ds$variables$sbp));stopifnot(max(abs(as.vector(b)-coef(fit)))<1e-7)}
  stopifnot(identical(hashes,tools::md5sum(paths)),survey::degf(ds)==15,all(vapply(models,function(f)nrow(f$model),integer(1))==5019))
  writeLines(capture.output(sessionInfo()),file.path(res,'sessionInfo.txt'))
  writeLines(c('PASS: raw XPT IDs unique; raw files unchanged; cleaning and complete-record criteria verified.',
    'PASS: 5019 complete records, 11 columns, CSV and XPT round-trip equal.',
    'PASS: all models use identical records, design degrees of freedom 15.',
    'No imputation, no machine learning, no train/test split; age forms are exploratory checks.',
    paste0('survey version: ',packageVersion('survey')),paste0('haven version: ',packageVersion('haven'))),file.path(res,'verification.txt'))
  print(all[all$term=='pir',],row.names=FALSE);print(diagnostics,row.names=FALSE)
}
run_analysis()

source(file.path("R", "render_figures.R"), encoding="UTF-8")
