      SUBROUTINE DDCOM4(NDOM,LDOM,MAX,
     *                  NPB1,LPB1,XPB1,YPB1,ZPB1,
     *                  NPB2,LPB2,XPB2,YPB2,ZPB2,
C Fujitsu start 202103
C     *                  MAXBUF,BUFSND,BUFRCV,
     *                  MAXBUF,rx_desc,ry_desc,
C Fujitsu end 202103
     *                  IUT0,IERR)
C Fujitsu start 202103
      use xmp_api
      use mpi
C Fujitsu end 202103
      IMPLICIT REAL*4 (A-H,O-Z)
      DIMENSION LDOM(NDOM),
     *          NPB1(    NDOM),NPB2(    NDOM),
     *          LPB1(MAX,NDOM),LPB2(MAX,NDOM),
     *          XPB1(MAX,NDOM),XPB2(MAX,NDOM),
     *          YPB1(MAX,NDOM),YPB2(MAX,NDOM),
C Fujitsu start 202103
C     *          ZPB1(MAX,NDOM),ZPB2(MAX,NDOM),
     *          ZPB1(MAX,NDOM),ZPB2(MAX,NDOM)
C     *          BUFSND(MAXBUF),BUFRCV(MAXBUF)
      REAL*4 , POINTER :: BUFSND ( : ) => null ( )
      REAL*4 , POINTER :: BUFRCV ( : ) => null ( )
      INTEGER*8 :: rx_desc, ry_desc
C
C      INCLUDE 'mpif.h'
C Fujitsu end 202103
C
      PARAMETER (MAXDOM=10000)
      DIMENSION MSGIDS(MAXDOM),MSGSTS(MPI_STATUS_SIZE,MAXDOM)
C
C
C      REAL NPB2_TMP(NDOM)[*]
C      REAL NPB1_TMP(NDOM)
C
C Fujitsu start 202103
      call xmp_coarray_bind(rx_desc,BUFSND)
      call xmp_coarray_bind(ry_desc,BUFRCV)
C Fujitsu end 202103
C
C      DO 100 IDOM=1,NDOM
C        NPB2_TMP(IDOM)[LDOM(IDOM)]=NPB1_TMP(IDOM)
C  100 CONTINUE
CC! XMP SYNC_MEMORY
      WRITE(IUT6,*) 'NDOM======================================',NDOM
      DO 1000 IDOM=1,NDOM
          MSGLEN=1
          MSGTYP=1
          IRECV =LDOM(IDOM)-1
          CALL MPI_IRECV(NPB2(IDOM),MSGLEN,MPI_REAL,IRECV,MSGTYP,
     *                   MPI_COMM_WORLD,MSGIDS(IDOM),IERR)
 1000 CONTINUE
C
      DO 1100 IDOM=1,NDOM
          MSGLEN=1
          MSGTYP=1
          ISEND =LDOM(IDOM)-1
          CALL MPI_ISEND(NPB1(IDOM),MSGLEN,MPI_REAL,ISEND,MSGTYP,
     *                   MPI_COMM_WORLD,MSGIDS(NDOM+IDOM),IERR)
 1100 CONTINUE
C
      CALL MPI_WAITALL(2*NDOM,MSGIDS,MSGSTS,IERR)
C
      NSTART=1
      DO 2000 IDOM=1,NDOM
          MSGTYP=1
          IRECV =LDOM(IDOM)-1
          MSGLEN=4*NPB2(IDOM)
          CALL MPI_IRECV(BUFRCV(NSTART),MSGLEN,MPI_REAL,
     *                   IRECV,MSGTYP,MPI_COMM_WORLD,MSGIDS(IDOM),IERR)
          NSTART=NSTART+MSGLEN
 2000 CONTINUE
C
      NSTART=1
      DO 2100 IDOM=1,NDOM
          DO 2200 IBP=1,NPB1(IDOM)
              BUFSND(NSTART+0)=LPB1(IBP,IDOM)
              BUFSND(NSTART+1)=XPB1(IBP,IDOM)
              BUFSND(NSTART+2)=YPB1(IBP,IDOM)
              BUFSND(NSTART+3)=ZPB1(IBP,IDOM)
              NSTART=NSTART+4
 2200     CONTINUE
 2100 CONTINUE
C
      NSTART=1
      DO 2300 IDOM=1,NDOM
          MSGTYP=1
          ISEND =LDOM(IDOM)-1
          MSGLEN=4*NPB1(IDOM)
          CALL MPI_ISEND(BUFSND(NSTART),MSGLEN,MPI_REAL,ISEND,MSGTYP,
     *                   MPI_COMM_WORLD,MSGIDS(NDOM+IDOM),IERR)
          NSTART=NSTART+MSGLEN
 2300 CONTINUE
C
      CALL MPI_WAITALL(2*NDOM,MSGIDS,MSGSTS,IERR)
C  
      NSTART=1
      DO 3000 IDOM=1,NDOM
          DO 3100 IBP=1,NPB2(IDOM)
              LPB2(IBP,IDOM)=BUFRCV(NSTART+0) 
              XPB2(IBP,IDOM)=BUFRCV(NSTART+1) 
              YPB2(IBP,IDOM)=BUFRCV(NSTART+2) 
              ZPB2(IBP,IDOM)=BUFRCV(NSTART+3) 
              NSTART=NSTART+4
 3100     CONTINUE
 3000 CONTINUE
C
      RETURN
      END
