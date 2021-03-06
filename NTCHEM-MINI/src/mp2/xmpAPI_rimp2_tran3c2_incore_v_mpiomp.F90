      SUBROUTINE RIMP2_Tran3c2_InCore_V_MPIOMP
!
!     o three-center RI integral transformation from original aux. basis to transformed aux. basis
!       (ia|c) -> (ia|d)
!
      USE MP2_Module, ONLY : IOccBat, NOccBat, LenOccBat, NOccBat_per_Proc, NActO, NActV, Name
      USE RIMP2_Module, ONLY : NBF_RI, NBC_RI, RIInt2c, RI2cInv, RIInt3c2a, RIInt3c2b, RIInt3c3a, RIInt3c3b, &
     &   NBF_RI_MyRank, IdxBF_RI_MyRank
      USE MP2_Constant_Module, ONLY : Zero, One
      USE MPI_Module, ONLY : MPI_COMM_MO, NProcs, MyRank, NProcsMO, MyRankMO, NProcsMat, MyRankMat
      USE XMP_API
!
      IMPLICIT NONE
!
      INCLUDE 'mpif.h'
!
! #undef USE_GPU
!
#ifdef MPIINT8
#define MPI_INTEGER MPI_INTEGER8
#endif
!
      INTEGER :: MXNActO
      INTEGER :: IaBat, Ia, Ii, I, K
      INTEGER :: IaBg, IaEd, IaBg_Proc
      INTEGER :: IaBat_Proc, Irank_diff, Iranksend, Irankrecv
      INTEGER :: MXNBF_RI_MyRank
      INTEGER :: NT2BufSize
      INTEGER :: IErr
      INTEGER :: ireq(4)
      INTEGER :: Mod_NBF_RI_NProcsMat
      INTEGER :: leni, ibgn, idim
      REAL(8) :: TimeBgn, TimeEnd, WTimeBgn, WTimeEnd
!coarray
!     INTEGER, ALLOCATABLE :: IdxBF_RI_Irank(:)
!      INTEGER, ALLOCATABLE :: IdxBF_RI_Irank(:)[:]
      INTEGER, pointer :: IdxBF_RI_Irank(:) => null()
      INTEGER(8) :: IdxBF_RI_Irank_desc
      integer(8), dimension(1) :: IdxBF_RI_Irank_lb,IdxBF_RI_Irank_ub
      integer(8) :: IdxBF_RI_Irank_sec
!!
      INTEGER, ALLOCATABLE :: istat1(:), istat2(:), istat3(:), istat4(:)
#ifdef USE_GPU
      REAL(8), ALLOCATABLE, pinned :: T2Int(:,:,:,:)
      real(8), parameter :: maxMem = 1e9
      ! real(8), parameter :: maxMem = 1e8
      integer, parameter :: Num_Stream = 3
      integer, parameter :: Num_Buf = 2
      integer :: devptr_A, devptr_B(Num_Stream), devptr_C(Num_Stream)
      integer :: id_st
#else
      REAL(8), ALLOCATABLE :: T2Int(:,:,:,:)
      integer, parameter :: Num_Buf = 1
#endif
!coarray
!     REAL(8), ALLOCATABLE :: T2BufSend(:,:,:), T2BufRecv(:,:,:)
!      REAL(8), ALLOCATABLE :: T2BufSend(:,:,:), T2BufRecv(:,:,:)[:]
      REAL(8), ALLOCATABLE :: T2BufSend(:,:,:) 
!local xmp-api
      ! xmp_array_section_t
      integer(8) :: T2BufSend_local_sec
      ! xmp_desc_t
      integer(8) :: T2BufSend_local_desc
      ! array size
      integer(8),dimension(3) :: T2BufSend_lb, T2BufSend_ub

      REAL(8), pointer ::  T2BufRecv(:,:,:) => null()
      INTEGER(8) :: T2BufRecv_desc
      integer(8), dimension(3) :: T2BufRecv_lb,T2BufRecv_ub
      integer(8) :: T2BufRecv_sec
! local xmp-api
      ! xmp_array_section_t
      integer(8) :: IdxBF_RI_MyRank_local_sec
      ! xmp_desc_t
      integer(8) :: IdxBF_RI_MyRank_local_desc
      ! xmp_array_section_t
      !integer(8) :: IdxBF_RI_MyRank_local
      integer(8),dimension(1) :: IdxBF_RI_MyRank_lb, IdxBF_RI_MyRank_ub

      integer(4) status
      integer(4) ::  img_dims(1)

!!
!
      REAL(8) :: Time_T2C, Time_T3, WTime_T2C, WTime_T3
!
      integer :: lm, ln, lk
      integer :: maxBlkN, stpBlkN, numBlkN
      integer :: maxMN, maxLenN, maxLenM
      integer :: j
      integer :: id_buf
!
      Time_T2C = Zero
      Time_T3 = Zero
      WTime_T2C = Zero
      WTime_T3 = Zero
!
      leni = NBF_RI / NProcsMat
      Mod_NBF_RI_NProcsMat = MOD(NBF_RI, NProcsMat)
      if (Mod_NBF_RI_NProcsMat > MyRankMat) then
         ibgn = leni * MyRankMat + MyRankMat + 1
         idim = leni + 1
      else
         ibgn = leni * MyRankMat + Mod_NBF_RI_NProcsMat + 1
         idim = leni
      end if
!      
!      if (MyRank == 0) then
!         write(*, *) 'MyRankMat=', MyRankMat
!         write(*, *) 'leni=', leni
!         write(*, *) 'ibgn=', ibgn
!         write(*, *) 'idim=', idim
!      end if
!
      ALLOCATE(RIInt2c(NBC_RI))
!      CALL DCOPY(NBC_RI, Zero, 0, RIInt2c, 1)
!
!     o Evaluation of two-center RI integrals (P|Q)
!
      IF (MyRank == 0) THEN
         PRINT '(" ..... Enter    (RIInt2_MDInt2c  )")'
      END IF
      WTimeBgn = MPI_WTIME()
      CALL CPU_TIME(TimeBgn)
      CALL RIMP2_RIInt2_MDInt2_Int2c_MPIOMP
      CALL CPU_TIME(TimeEnd)
      WTimeEnd = MPI_WTIME()
      IF (MyRank == 0) THEN
         PRINT '(" ..... CPU time (RIInt2_MDInt2c  ) :", F12.2)', TimeEnd - TimeBgn
         PRINT '(" ..... WALL time (RIInt2_MDInt2c  ) :", F12.2)', WTimeEnd - WTimeBgn
      END IF
!
      ALLOCATE(RI2cInv(NBF_RI, NBF_RI))
!
!     o Calculation of the inverse matrix of two-center RI integrals (P|Q)^-1
!
      IF (MyRank == 0) THEN
         PRINT '(" ..... Enter    (RIInt2_Inv2c    )")'
      END IF
      WTimeBgn = MPI_WTIME()
      CALL CPU_TIME(TimeBgn)
      CALL RIMP2_Inv2c_MPI
      CALL CPU_TIME(TimeEnd)
      WTimeEnd = MPI_WTIME()
      IF (MyRank == 0) THEN
         PRINT '(" ..... CPU time (RIInt2_Inv2c    ) :", F12.2)', TimeEnd - TimeBgn
         PRINT '(" ..... WALL time (RIInt2_Inv2c    ) :", F12.2)', WTimeEnd - WTimeBgn
      END IF
!
      DEALLOCATE(RIInt2c)
!
!     o Allocation of memory
!
      MXNActO = MAX(NActO(1), NActO(2))
      MXNBF_RI_MyRank = MAXVAL(NBF_RI_MyRank)
      NT2BufSize = MXNActO * LenOccBat * MXNBF_RI_MyRank
      ALLOCATE(T2Int(NBF_RI,MXNActO,LenOccBat, Num_Buf))
!coarray
!     ALLOCATE(IdxBF_RI_Irank(MXNBF_RI_MyRank))
!      ALLOCATE(IdxBF_RI_Irank(MXNBF_RI_MyRank)[*])

      IdxBF_RI_Irank_lb(1) = 1
      IdxBF_RI_Irank_ub(1) = MXNBF_RI_MyRank
      call xmp_new_coarray(IdxBF_RI_Irank_desc,4,1,IdxBF_RI_Irank_lb, &
      IdxBF_RI_Irank_ub,1,img_dims)
      call xmp_coarray_bind(IdxBF_RI_Irank_desc,IdxBF_RI_Irank)

!!
      ALLOCATE(istat1(MPI_STATUS_SIZE))
      ALLOCATE(istat2(MPI_STATUS_SIZE))
      ALLOCATE(istat3(MPI_STATUS_SIZE))
      ALLOCATE(istat4(MPI_STATUS_SIZE))

      ALLOCATE(T2BufSend(MXNActO,MXNBF_RI_MyRank,LenOccBat))
      T2BufSend_lb(1) = 1
      T2BufSend_lb(2) = 1
      T2BufSend_lb(3) = 1
      T2BufSend_ub(1) = MXNActO
      T2BufSend_ub(2) = MXNBF_RI_MyRank
      T2BufSend_ub(3) = LenOccBat
      call xmp_new_local_array(T2BufSend_local_desc,8,3,T2BufSend_lb, &
       T2BufSend_ub,loc(T2BufSend))
      call xmp_new_array_section(T2BufSend_local_sec,3)

      IdxBF_RI_MyRank_lb(1) = 1
      IdxBF_RI_MyRank_ub(1) = NBF_RI
      call xmp_new_local_array(IdxBF_RI_MyRank_local_desc,4,1,IdxBF_RI_MyRank_lb, &
       IdxBF_RI_MyRank_ub,loc(IdxBF_RI_MyRank))

      call xmp_new_array_section(IdxBF_RI_MyRank_local_sec,1)
      call xmp_new_array_section(IdxBF_RI_Irank_sec,1)
            

!coarray
!     ALLOCATE(T2BufRecv(MXNActO,MXNBF_RI_MyRank,LenOccBat))
!      ALLOCATE(T2BufRecv(MXNActO,MXNBF_RI_MyRank,LenOccBat)[*])
      T2BufRecv_lb(1)=1
      T2BufRecv_lb(2)=1
      T2BufRecv_lb(3)=1
      T2BufRecv_ub(1)=MXNActO
      T2BufRecv_ub(2)=MXNBF_RI_MyRank
      T2BufRecv_ub(3)=LenOccBat
      call xmp_new_coarray(T2BufRecv_desc,8,3,T2BufRecv_lb,T2BufRecv_ub,1,img_dims)
      call xmp_coarray_bind(T2BufRecv_desc,T2BufRecv)
      call xmp_new_array_section(T2BufRecv_sec,3)
!!
!
      ! test
      lm = idim
      ln = NActO(1)
      lk = NBF_RI   ! do not partition this

#ifdef DEBUG
      if ( MyRank == 0 ) then
         write(*,'(a,3i6)') "# (lm,ln,lk) = ", lm, ln, lk
      endif
#endif

      maxLenM = idim

#ifdef USE_GPU
      maxMN = sqrt(maxMem/8 + lk*lk) - lk
      maxBlkN = maxMN / ln
      if ( maxLenM > maxMN ) then
         maxLenM = maxMN
         maxLenM = maxLenM - mod(maxLenM, 32)
      endif

#ifdef DEBUG
      if ( MyRank == 0 ) then
         write(*,'(a,i6,a,i6,a,i6,a,i6)') &
              "# maxMN = ", maxMN, &
              ", maxLenM = ", maxLenM, &
              ", maxLenN = ", maxBlkN * NActO(1), &
              ", maxBlkN = ", maxBlkN
      endif
#endif

      lm = maxLenM
      ln = NActO(1) * maxBlkN
      call cublas_init()
      call cublas_alloc( devptr_A, lm, lk )
      DO id_st = 1, Num_Stream
         call cublas_alloc( devptr_B(id_st), lk, ln )
         call cublas_alloc( devptr_C(id_st), lm, ln )
      End DO
#endif

      ! test
!      CALL MPI_Barrier( MPI_COMM_MO, ierr )
!      sync all
      call xmp_sync_all(status)
!
!
!MPI Parallel
      DO IaBat_Proc = 1, NOccBat_per_Proc
!MPI Parallel
         id_buf = mod(IaBat_Proc-1, Num_Buf) + 1
!
!        o Send and recieve the 2/3 transformed 3c RI integrals (ia|c)
!
         ! ALLOCATE(T2BufSend(MXNActO,MXNBF_RI_MyRank,LenOccBat))
         ! ALLOCATE(T2BufRecv(MXNActO,MXNBF_RI_MyRank,LenOccBat))
         DO Irank_diff = 0, (NProcsMO - 1)
            Irankrecv = MyRankMO + Irank_diff
            Iranksend = MyRankMO - Irank_diff
            IF (Irankrecv >= NProcsMO) Irankrecv = Irankrecv - NProcsMO
            IF (Iranksend < 0)         Iranksend = Iranksend + NProcsMO
            IaBat = Iranksend * NOccBat_per_Proc + IaBat_Proc
            IaBg = IOccBat(1,IaBat,1) + 1
            IaEd = IOccBat(1,IaBat,1) + IOccBat(2,IaBat,1)
!
#ifdef DEBUG
            if ( MyRank == 0 ) then
               write(*,'(a,i6,i6)') "# Irank_diff", Irank_diff, (NProcsMO - 1)
            endif
#endif
!
            DO K = 1, NBF_RI_MyRank(MyRankMO)
               I = 0
               DO Ia = IaBg, IaEd
                  I = I + 1
                  DO Ii = 1, NActO(1)
                     T2BufSend(Ii,K,I) = RIInt3c2a(Ii+(Ia-1)*NActO(1),K)
                  END DO
               END DO
            END DO
!
!            sync all
            call xmp_sync_all(status)
            WTimeBgn = MPI_WTIME()
            CALL CPU_TIME(TimeBgn)

            call xmp_array_section_set_triplet(IdxBF_RI_MyRank_local_sec, &
             1,int(1,kind=8),int(NBF_RI_MyRank(MyRankMO),kind=8),1,status)
            call xmp_array_section_set_triplet(IdxBF_RI_Irank_sec, &
             1,int(1,kind=8),int(NBF_RI_MyRank(MyRankMO),kind=8),1,status)
            img_dims(1) = Iranksend+1

!            IdxBF_RI_Irank(1:NBF_RI_MyRank(MyRankMO))[Iranksend+1] = &
!            IdxBF_RI_MyRank(1:NBF_RI_MyRank(MyRankMO))
            call xmp_coarray_put_local(img_dims,IdxBF_RI_Irank_desc,IdxBF_RI_Irank_sec, &
             IdxBF_RI_MyRank_local_desc,IdxBF_RI_MyRank_local_sec,status) 
!            sync all
            call xmp_sync_all(status)
!!

!coarray
!           CALL MPI_IRecv(T2BufRecv, NT2BufSize, MPI_DOUBLE_PRECISION, Irankrecv, 1, MPI_COMM_MO, ireq(4), IErr)
!           CALL MPI_ISend(T2BufSend, NT2BufSize, MPI_DOUBLE_PRECISION, Iranksend, 1, MPI_COMM_MO, ireq(3), IErr)
!           CALL MPI_Wait(ireq(3), istat3, IErr)
!           CALL MPI_Wait(ireq(4), istat4, IErr)

            call xmp_array_section_set_triplet(T2BufSend_local_sec, &
             1,int(1,kind=8),int(MXNActO,kind=8),1,status)
            call xmp_array_section_set_triplet(T2BufSend_local_sec, &
             2,int(1,kind=8),int(MXNBF_RI_MyRank,kind=8),1,status)
            call xmp_array_section_set_triplet(T2BufSend_local_sec, &
             3,int(1,kind=8),int(LenOccBat,kind=8),1,status)

            call xmp_array_section_set_triplet(T2BufRecv_sec, &
             1,int(1,kind=8),int(MXNActO,kind=8),1,status)
            call xmp_array_section_set_triplet(T2BufRecv_sec, &
             2,int(1,kind=8),int(MXNBF_RI_MyRank,kind=8),1,status)
            call xmp_array_section_set_triplet(T2BufRecv_sec, &
             3,int(1,kind=8),int(LenOccBat,kind=8),1,status)

            !T2BufRecv(:,:,:)[Iranksend+1] = T2BufSend(:,:,:)
            !sync all
            img_dims(1) = Iranksend+1
            call xmp_coarray_put_local(img_dims, &
             T2BufRecv_desc, T2BufRecv_sec, &
             T2BufSend_local_desc, T2BufSend_local_sec,status) 
!            sync all
            call xmp_sync_all(status)

!!
            CALL CPU_TIME(TimeEnd)
            WTimeEnd = MPI_WTIME()
            Time_T2C = Time_T2C + TimeEnd - TimeBgn
            WTime_T2C = WTime_T2C + WTimeEnd - WTimeBgn
!
            IaBat = MyRankMO * NOccBat_per_Proc + IaBat_Proc
            DO I = 1, IOccBat(2,IaBat,1)
               DO K = 1, NBF_RI_MyRank(Irankrecv)
                  DO Ii = 1, NActO(1)
                     T2Int(IdxBF_RI_Irank(K),Ii,I,id_buf) = T2BufRecv(Ii,K,I)
                  END DO
               END DO
            END DO

            !
            ! work-around to avoid to stop MPI comm for some unknown reason
            !
            if ( mod(Irank_diff, 4) == 0 ) then
!coarray
!               CALL MPI_Barrier( MPI_COMM_MO, ierr )
!               sync all
               call xmp_sync_all(status)
!!
            endif

         END DO
         ! DEALLOCATE(T2BufSend)
         ! DEALLOCATE(T2BufRecv)
!
         IaBat = MyRankMO * NOccBat_per_Proc + 1
         IaBg_Proc = IOccBat(1,IaBat,1)
         IaBat = MyRankMO * NOccBat_per_Proc + IaBat_Proc
         IaBg = IOccBat(1,IaBat,1)
!
         stpBlkN = 1
#ifdef USE_GPU
         stpBlkN = maxBlkN
         if ( stpBlkN > IOccBat(2,IaBat,1) ) then
            stpBlkN = (IOccBat(2,IaBat,1) + 1) / 2
         endif
#endif
!
#ifdef DEBUG
         if ( MyRank == 0 ) then
            write(*,'(a,i6,a,i6)') "# IOccBat(2,IaBat,1) = ", IOccBat(2,IaBat,1), &
                 ", stpBlkN = ", stpBlkN
            write(*,'(a,i6,i4,a,i4,i6)') "# (m,n,k) = ", idim, NActO(1), 'x', stpBlkN, NBF_RI
         endif
#endif
!
         DO J = 1, idim, maxLenM    ! insert this loop to do blocking in m-direction of dgemm
            lk = NBF_RI
            lm = idim - (J-1)
            if ( lm > maxLenM ) lm = maxLenM

#ifdef USE_GPU
            DO id_st = 1, Num_Stream
               call cublas_st_sync( id_st )
            End DO
            call cublas_set_matrix( lk, lm, RI2cInv(1,ibgn+(J-1)), lk, devptr_A, lk )
            id_st = 1
#endif

            DO I = 1, IOccBat(2,IaBat,1), stpBlkN
               Ia = (IaBg + I) - IaBg_Proc

               numBlkN = IOccBat(2,IaBat,1) - I + 1
               if ( numBlkN > stpBlkN ) numBlkN = stpBlkN
               ln = NActO(1) * numBlkN
! #ifdef DEBUG
!                if ( MyRank == 0 ) then
!                   write(*,'(a,i4,a,i4,a,3i6)') "# J=", J, ", I=", I, ", (lm,ln,lk)=", lm,ln,lk
!                endif
! #endif               
!
!              o 3/3 integral transformation
!                (ia|P) -> (iq|Q)
!
               WTimeBgn = MPI_WTIME()
               CALL CPU_TIME(TimeBgn)
#ifdef USE_GPU
               id_st = mod(id_st, Num_Stream) + 1
               call cublas_set_matrix_async( lk, ln, T2Int(1,1,I,id_buf), lk, devptr_B(id_st), lk, id_st )
               call cublas_dgemm_async('T', 'N', lm, ln, lk, One, &
                    devptr_A, NBF_RI, &
                    devptr_B(id_st), NBF_RI, Zero, &
                    devptr_C(id_st), maxLenM, id_st )
               call cublas_get_matrix_async( lm, ln, devptr_C(id_st), maxLenM, RIInt3c3a(J,Ia), idim, id_st )
#else
               ! CALL DGEMM('T', 'N', lm, ln, lk, One, &
               !      RI2cInv(1,ibgn), NBF_RI, &
               !      T2Int(1,1,I,id_buf), NBF_RI, Zero, &
               !      RIInt3c3a(1,Ia), idim )
               CALL DGEMM('T', 'N', lm, ln, lk, One, &
                    RI2cInv(1,ibgn+(J-1)), NBF_RI, &
                    T2Int(1,1,I,id_buf), NBF_RI, Zero, &
                    RIInt3c3a(J,Ia), idim )
#endif
               CALL CPU_TIME(TimeEnd)
               WTimeEnd = MPI_WTIME()
               Time_T3 = Time_T3 + TimeEnd - TimeBgn
               WTime_T3 = WTime_T3 + WTimeEnd - WTimeBgn
!
            End DO
!
!
         END DO
!
      END DO
!
#ifdef USE_GPU
      DO id_st = 1, Num_Stream
         call cublas_st_sync( id_st )
      End DO
      call cublas_free( devptr_A )
      DO id_st = 1, Num_Stream
         call cublas_free( devptr_B(id_st) )
         call cublas_free( devptr_C(id_st) )
      End DO
#endif

      IF (MyRank == 0) THEN
         PRINT '(" ..... CPU time (2/3 tran3c2 comm) :", F12.2)', Time_T2C
         PRINT '(" ..... CPU time (3/3 tran3c2 tran) :", F12.2)', Time_T3
         PRINT '(" ..... WALL time (2/3 tran3c2 comm) :", F12.2)', WTime_T2C
         PRINT '(" ..... WALL time (3/3 tran3c2 tran) :", F12.2)', WTime_T3
      END IF


      ! allocate section
      call xmp_free_array_section(IdxBF_RI_Irank_sec)
      call xmp_free_array_section(IdxBF_RI_MyRank_local_sec)
      call xmp_free_array_section(T2BufSend_local_sec)
      call xmp_free_array_section(T2BufRecv_sec)


!
!     o deallocate memory
!
      !DEALLOCATE(T2BufSend)
!      call xmp_coarray_deallocate(T2BufSend_local_desc,status)
      call xmp_free_local_array(T2BufSend_local_desc)

      !DEALLOCATE(T2BufRecv)
      call xmp_coarray_deallocate(T2BufRecv_desc,status)

      !DEALLOCATE(IdxBF_RI_MyRank)
!      call xmp_coarray_deallocate(IdxBF_RI_MyRank_local_desc,status)
      call xmp_free_local_array(IdxBF_RI_MyRank_local_desc)

      !DEALLOCATE(IdxBF_RI_Irank)
      call xmp_coarray_deallocate(IdxBF_RI_Irank_desc,status)

      DEALLOCATE(RI2cInv)
      DEALLOCATE(T2Int)
      DEALLOCATE(NBF_RI_MyRank)
      DEALLOCATE(istat1)
      DEALLOCATE(istat2)
      DEALLOCATE(istat3)
      DEALLOCATE(istat4)
!
      END SUBROUTINE
