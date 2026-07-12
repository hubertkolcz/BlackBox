/* d1_k3_maxclique.c -- exact maximum clique solver for the D1 k=3
 * copy-activation brackets (C7, Petersen, Paley(13); companion to
 * d1-k3-brackets-2026-07-11.md and d1_k3_graphs.py).
 *
 * Bitset branch-and-bound with a greedy-coloring upper bound per branch
 * (the standard Tomita/Tanaka/Takahashi "MCQ" algorithm). Reads a packed
 * adjacency file written by d1_k3_graphs.py:
 *   int64 N; int64 WORDS; then N*WORDS uint64 words (row-major), where bit b
 *   of word w in row i means vertex i is adjacent to vertex (w*64+b).
 *
 * --reduce: every graph here is an OR-power of a vertex-transitive base
 * graph, hence itself vertex-transitive (if phi_1..phi_k are base-graph
 * automorphisms with phi_i(u_i)=v_i, then (phi_1,...,phi_k) is an
 * automorphism of G^(OR k) mapping tuple u to v). So SOME maximum clique
 * contains vertex 0 WLOG -- this restricts the search to the induced
 * subgraph on N(0), plus 1. Exact (not heuristic); validated by checking
 * --reduce and non-reduce modes agree on every graph small enough to run
 * both (see d1-k3-brackets-2026-07-11.md, "Method").
 *
 * --timelimit S: internal wall-clock cap in seconds. This sandbox has no
 * working mechanism to persist a background process across tool calls
 * (nohup/disown do not survive the per-call container teardown here,
 * confirmed empirically), so long searches are resumed via repeated short
 * foreground invocations instead, using:
 *
 * --toplevel-lo L --toplevel-hi H: restrict the DEPTH-0 branch loop to
 * order-array index range [L,H] (indices are positions in the
 * greedy-coloring order, ascending by color; the search iterates from
 * high color to low). This lets a large top-level loop be split across
 * many separate invocations.
 * --initial-best K: seed the incumbent (in FINAL, i.e. post "+1 for vertex
 * 0", units) before searching, both for correct pruning and so repeated
 * invocations can carry forward the best clique found so far. Each
 * invocation's local best, maximized over all invocations/ranges, is
 * always a valid global lower bound regardless of seeding; the seed is
 * purely a pruning speed-up, not required for correctness.
 *
 * Prints progress (new incumbent + elapsed time) to stderr, so a
 * timed-out run still yields a certified valid lower-bound witness. At the
 * end, independently re-verifies the witness clique against the RAW
 * (unreduced, unrelabeled) adjacency read fresh from the file -- a
 * different code path from the search itself.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

typedef uint64_t u64;

static long long N, WORDS;
static u64 *ADJ; /* raw N*WORDS, from file */

static inline int popcnt(const u64*a,int w){int c=0;for(int i=0;i<w;i++)c+=__builtin_popcountll(a[i]);return c;}
static inline int anybits(const u64*a,int w){for(int i=0;i<w;i++) if(a[i]) return 1; return 0;}
static inline int pickbit(const u64*a,int w){for(int i=0;i<w;i++) if(a[i]) return i*64+__builtin_ctzll(a[i]); return -1;}
static inline void clearbit(u64*a,int i){a[i/64]&=~((u64)1<<(i%64));}
static inline void setbit(u64*a,int i){a[i/64]|=((u64)1<<(i%64));}
static inline int testbit(const u64*a,int i){return (int)((a[i/64]>>(i%64))&1ULL);}
static inline void andb(u64*d,const u64*a,const u64*b,int w){for(int i=0;i<w;i++) d[i]=a[i]&b[i];}
static inline void andnotb(u64*d,const u64*a,const u64*b,int w){for(int i=0;i<w;i++) d[i]=a[i]&~b[i];}

#define MAXDEPTH 1024
static int M, W2;         /* size / word-count of the (sub)graph we search  */
static u64 *SADJ;          /* M*W2 adjacency actually searched               */
static u64 *bufP[MAXDEPTH], *bufPw[MAXDEPTH];
static u64 *bufPleft[MAXDEPTH], *bufQ[MAXDEPTH], *bufTmp[MAXDEPTH];
static int *bufOrder[MAXDEPTH], *bufColor[MAXDEPTH];
static int Rstack[MAXDEPTH];
static int best=0, bestClique[MAXDEPTH];
static long long nodes=0;
static time_t t0;
static double time_limit=-1;
static int timed_out=0;
static int toplevel_lo=-1, toplevel_hi=-1; /* inclusive index range into depth-0 color order; -1 = unrestricted */
static int toplevel_reached_break=0;
static int toplevel_last_i=-1;


static int color_sort(int depth, const u64*P){
    int w=W2;
    u64 *Pleft=bufPleft[depth], *Q=bufQ[depth], *tmp=bufTmp[depth];
    int *order=bufOrder[depth], *colorNum=bufColor[depth];
    memcpy(Pleft,P,w*sizeof(u64));
    int cnt=0,color=0;
    while(anybits(Pleft,w)){
        color++;
        memcpy(Q,Pleft,w*sizeof(u64));
        while(anybits(Q,w)){
            int v=pickbit(Q,w);
            order[cnt]=v; colorNum[cnt]=color; cnt++;
            clearbit(Pleft,v);
            andnotb(tmp,Q, SADJ+(size_t)v*w, w);
            clearbit(tmp,v);
            memcpy(Q,tmp,w*sizeof(u64));
        }
    }
    return cnt;
}

static void expand(int depth,int Rsize){
    nodes++;
    if(timed_out) return;
    if(time_limit>0 && (nodes & 0xFFFULL)==0){
        if((double)(time(NULL)-t0) > time_limit){ timed_out=1; return; }
    }
    u64 *P=bufP[depth];
    int w=W2;
    int cnt=popcnt(P,w);
    if(cnt==0){
        if(Rsize>best){
            best=Rsize;
            memcpy(bestClique,Rstack,Rsize*sizeof(int));
            fprintf(stderr,"[progress] new best=%d nodes=%lld elapsed=%lds\n", best, nodes, (long)(time(NULL)-t0));
            fflush(stderr);
        }
        return;
    }
    int m = color_sort(depth, P);
    int *order=bufOrder[depth], *colorNum=bufColor[depth];
    u64 *Pw = bufPw[depth];
    memcpy(Pw, P, w*sizeof(u64));
    int iHi = m-1, iLo = 0;
    if(depth==0 && toplevel_lo>=0){ iLo = toplevel_lo; iHi = (toplevel_hi>=0 && toplevel_hi<iHi)? toplevel_hi : iHi; }
    for(int i=iHi;i>=iLo;i--){
        if(timed_out) break;
        int v=order[i], c=colorNum[i];
        if(Rsize + c <= best){ if(depth==0) toplevel_reached_break=1; break; }
        Rstack[Rsize]=v;
        u64 *newP = bufP[depth+1];
        andb(newP, Pw, SADJ+(size_t)v*w, w);
        expand(depth+1, Rsize+1);
        clearbit(Pw, v);
        if(depth==0) toplevel_last_i = i;
    }
}

int main(int argc, char**argv){
    if(argc<2){ fprintf(stderr,"usage: %s file.bin [--reduce] [--timelimit S]\n",argv[0]); return 1; }
    int reduce=0; double tl=-1; int ilo=-1, ihi=-1, ibest=0;
    for(int i=2;i<argc;i++){
        if(!strcmp(argv[i],"--reduce")) reduce=1;
        else if(!strcmp(argv[i],"--timelimit") && i+1<argc){ tl=atof(argv[++i]); }
        else if(!strcmp(argv[i],"--toplevel-lo") && i+1<argc){ ilo=atoi(argv[++i]); }
        else if(!strcmp(argv[i],"--toplevel-hi") && i+1<argc){ ihi=atoi(argv[++i]); }
        else if(!strcmp(argv[i],"--initial-best") && i+1<argc){ ibest=atoi(argv[++i]); }
    }
    toplevel_lo = ilo; toplevel_hi = ihi;
    FILE *f=fopen(argv[1],"rb");
    if(!f){ perror("fopen"); return 1; }
    if(fread(&N,sizeof(N),1,f)!=1){fprintf(stderr,"read N failed\n");return 1;}
    if(fread(&WORDS,sizeof(WORDS),1,f)!=1){fprintf(stderr,"read WORDS failed\n");return 1;}
    ADJ = malloc((size_t)N*WORDS*sizeof(u64));
    size_t need=(size_t)N*WORDS;
    if(fread(ADJ,sizeof(u64),need,f)!=need){fprintf(stderr,"read ADJ failed\n");return 1;}
    fclose(f);
    fprintf(stderr,"[info] loaded N=%lld WORDS=%lld deg(0)=%d reduce=%d timelimit=%.1f\n",
            N, WORDS, popcnt(ADJ,(int)WORDS), reduce, tl);

    int *origId=NULL; /* maps subgraph vertex id -> original vertex id (only if reduce) */
    if(reduce){
        u64 *row0 = ADJ; /* vertex 0's row */
        /* collect neighbors of vertex 0 */
        int cnt=0;
        for(long long j=0;j<N;j++) if(testbit(row0,(int)j)) cnt++;
        origId = malloc(cnt*sizeof(int));
        int idx=0;
        for(long long j=0;j<N;j++) if(testbit(row0,(int)j)) origId[idx++]=(int)j;
        M = cnt;
        W2 = (M+63)/64;
        SADJ = calloc((size_t)M*W2, sizeof(u64));
        for(int a=0;a<M;a++){
            int oa = origId[a];
            u64 *orow = ADJ + (size_t)oa*WORDS;
            for(int b=0;b<M;b++){
                if(a==b) continue;
                int ob = origId[b];
                if(testbit(orow, ob)) setbit(SADJ+(size_t)a*W2, b);
            }
        }
        fprintf(stderr,"[info] reduced to induced subgraph on N(0): M=%d W2=%d\n", M, W2);
    } else {
        M=(int)N; W2=(int)WORDS; SADJ=ADJ;
        origId = malloc(M*sizeof(int));
        for(int i=0;i<M;i++) origId[i]=i;
    }

    /* degree-descending relabel within the searched subgraph, purely a
     * search-order heuristic -- does not change correctness. */
    int *deg = malloc(M*sizeof(int));
    for(int i=0;i<M;i++) deg[i]=popcnt(SADJ+(size_t)i*W2, W2);
    int *perm = malloc(M*sizeof(int));
    for(int i=0;i<M;i++) perm[i]=i;
    /* simple insertion-free sort via qsort with index trick */
    int *degCopy = deg; /* for comparator via closure-less qsort we use a static ptr */
    /* comparator needs static access to degCopy; emulate with global */
    extern int cmp_desc_deg(const void*,const void*);
    /* use a small local static to avoid extra globals plumbing issues */
    { 
        /* implement sort manually (M is at most ~2200, O(M log M) trivial) */
        for(int i=1;i<M;i++){
            int key=perm[i], kd=deg[key];
            int j=i-1;
            while(j>=0 && deg[perm[j]] < kd){ perm[j+1]=perm[j]; j--; }
            perm[j+1]=key;
        }
    }
    u64 *SADJ2 = calloc((size_t)M*W2, sizeof(u64));
    int *inv = malloc(M*sizeof(int)); /* inv[old] = new */
    for(int newi=0; newi<M; newi++) inv[perm[newi]] = newi;
    for(int newi=0; newi<M; newi++){
        int oldi = perm[newi];
        u64 *oldrow = SADJ + (size_t)oldi*W2;
        for(int oldj=0; oldj<M; oldj++){
            if(oldj==oldi) continue;
            if(testbit(oldrow, oldj)) setbit(SADJ2+(size_t)newi*W2, inv[oldj]);
        }
    }
    /* remap origId through perm so SADJ2's vertex i is origId[perm[i]] in the
     * ORIGINAL global graph */
    int *origId2 = malloc(M*sizeof(int));
    for(int newi=0; newi<M; newi++) origId2[newi] = origId[perm[newi]];

    if(reduce) free(SADJ); /* replace with relabeled version */
    SADJ = SADJ2;
    free(origId); origId = origId2;
    free(deg); free(perm); free(inv);

    /* allocate depth-indexed scratch buffers */
    for(int d=0; d<MAXDEPTH; d++){
        bufP[d]=malloc(W2*sizeof(u64));
        bufPw[d]=malloc(W2*sizeof(u64));
        bufPleft[d]=malloc(W2*sizeof(u64));
        bufQ[d]=malloc(W2*sizeof(u64));
        bufTmp[d]=malloc(W2*sizeof(u64));
        bufOrder[d]=malloc(M*sizeof(int));
        bufColor[d]=malloc(M*sizeof(int));
    }
    memset(bufP[0],0,W2*sizeof(u64));
    for(int i=0;i<M;i++) setbit(bufP[0], i);

    time_limit = tl;
    t0 = time(NULL);
    best = ibest>0 ? ibest-(reduce?1:0) : 0;
    if(best<0) best=0;
    for(int z=0; z<MAXDEPTH; z++) bestClique[z]=-1;
    expand(0,0);

    int finalSize = reduce ? best+1 : best;
    printf("RESULT graph_N=%lld reduce=%d M=%d search_best=%d final_omega=%d timed_out=%d nodes=%lld elapsed=%lds toplevel_lo=%d toplevel_hi=%d toplevel_reached_break=%d toplevel_last_i=%d\n",
           N, reduce, M, best, finalSize, timed_out, nodes, (long)(time(NULL)-t0), toplevel_lo, toplevel_hi, toplevel_reached_break, toplevel_last_i);

    /* Build the witness in ORIGINAL global vertex ids */
    int witnessCount = reduce ? best+1 : best;
    int *witness = malloc(witnessCount>0?witnessCount*sizeof(int):sizeof(int));
    int wi=0;
    int haveWitness = (best>0) && (bestClique[0]>=0);
    if(!haveWitness){
        printf("WITNESS_VERIFIED=SKIPPED (no improvement over seeded initial-best in this chunk)\n");
    } else {
    if(reduce) witness[wi++]=0; /* vertex 0 itself */
    for(int i=0;i<best;i++) witness[wi++] = origId[bestClique[i]];

    /* independent re-verification directly against RAW ADJ (not SADJ/relabeled) */
    int ok=1;
    for(int a=0; a<witnessCount && ok; a++){
        for(int b=a+1;b<witnessCount; b++){
            int u=witness[a], v=witness[b];
            if(u==v){ ok=0; break; }
            u64 *urow = ADJ + (size_t)u*WORDS;
            if(!testbit(urow, v)){ ok=0; break; }
        }
    }
    printf("WITNESS_VERIFIED=%d size=%d vertices=", ok, witnessCount);
    for(int i=0;i<witnessCount;i++) printf("%d%s", witness[i], (i+1<witnessCount)?",":"");
    printf("\n");
    }
    return 0;
}
