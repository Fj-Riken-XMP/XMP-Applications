  subroutine copy(buf1, buf2, n)
  !--- 2020 Fujitsu
  use xmp_api
  !--- 2020 Fujitsu end
  implicit none
  integer :: n
  complex(8) :: buf1(n), buf2(n)
  
  buf1(:) = buf2(:)
  return
  end subroutine copy

#include "config.h"

module comlib
!= Communication subroutines wrapping MPI.
!
!== Abstract
!
! MPI1 Isend-irecv-Wait is used.
!
! Uses
!                                MPI1                         
! - 0 comlib_make2          :                                   
! - 1 comlib_irecv          :  MPI_irecv                        
! - 2 comlib_isend          :  MPI_Isend                        
! - 3 comlib_check          :  MPI_Wait(recv)/MPI_Wait(isend)   
!
!  node | 3              0               1               2               3               0
! =======================================================================================================
!  buff |   recv | send     recv | send     recv | send     recv | send     recv | send     recv | send
! =======================================================================================================
!          irecv |         irecv |         irecv |         irecv |         irecv |         irecv |
!                | isend =>      | isend =>      | isend =>      | isend =>      | isend =>      | irsend
!          wait  | wait    wait  | wait    wait  | wait    wait  | wait    wait  | wait    wait  |
! =======================================================================================================
!
!== Version
!
! $Id: comlib.F90,v 1.1 2009/12/02 10:24:23 ishikawa Exp $
!
  implicit none
  private 
  public :: comlib_data_c16
  public :: comlib_data_c8
  public :: comlib_init
  public :: comlib_finalize
  public :: comlib_node
  public :: comlib_make2
  public :: comlib_isend
  public :: comlib_irecv
  public :: comlib_sendrecv
  public :: comlib_check
  public :: comlib_barrier
  public :: comlib_bcast
  public :: comlib_sumcast

  integer, save :: myid,numprocs,ntag

  type comlib_data_c16
!
! Holds node, data sender/receiver information
!
    sequence
    private
    integer :: ssize,rsize,sdesc,rdesc,stag,rtag,sreq,rreq
    complex(8), pointer :: sbuff,rbuff,dummy0,dummy1
  end type

  type comlib_data_c8
!
! Holds node, data sender/receiver information
!
    sequence
    private
    integer :: ssize,rsize,sdesc,rdesc,stag,rtag,sreq,rreq
    complex(4), pointer :: sbuff,rbuff,dummy0,dummy1
  end type

  interface comlib_make2
    module procedure  comlib_make_c16
    module procedure  comlib_make_c8
  end interface

  interface comlib_isend
    module procedure  comlib_isend_c16
    module procedure  comlib_isend_c8
  end interface

  interface comlib_irecv
    module procedure  comlib_irecv_c16
    module procedure  comlib_irecv_c8
  end interface

  interface comlib_sendrecv
    module procedure  comlib_sendrecv_c16
    module procedure  comlib_sendrecv_c8
  end interface

  interface comlib_check
    module procedure  comlib_check_c16
    module procedure  comlib_check_c8
  end interface

  interface comlib_bcast
!
! General method to broadcast data
!
    module procedure  comlib_bcast_char
    module procedure  comlib_bcast_i4
    module procedure  comlib_bcast_r8
    module procedure  comlib_bcast_c16
    module procedure  comlib_bcast_i4_array
    module procedure  comlib_bcast_r8_array
    module procedure  comlib_bcast_c16_array
  end interface

  interface comlib_sumcast
!
! General method to take total sum and broadcast data
!
    module procedure  comlib_sumcast_i4
    module procedure  comlib_sumcast_r8
    module procedure  comlib_sumcast_r4
    module procedure  comlib_sumcast_c16
    module procedure  comlib_sumcast_c8
    module procedure  comlib_sumcast_i4_array
    module procedure  comlib_sumcast_r8_array
    module procedure  comlib_sumcast_r4_array
    module procedure  comlib_sumcast_c16_array
    module procedure  comlib_sumcast_c8_array
  end interface

  contains

subroutine comlib_bcast_char(arg,ids)
!
! Broadcast character
!
! - arg : character
! - ids : source destination
!
!coarray use mpi
  implicit none
  character(LEN=*), intent(inout) :: arg
  integer, intent(in) :: ids
  integer :: ilen,ierr

  ilen=LEN(arg)
!coarray  call MPI_BCAST(arg,ilen,MPI_CHARACTER,ids,MPI_COMM_WORLD,ierr)

  return
end subroutine

  subroutine comlib_bcast_i4(arg,ids)
!
! Broadcast integer
!
! - arg : integer
! - ids : source destination
!
  use mpi
  implicit none
  integer, intent(inout) :: arg
  integer, intent(in) :: ids
  integer :: ierr

!--- 2020 Fujitsu
  call MPI_BCAST(arg,1,MPI_INTEGER,ids,MPI_COMM_WORLD,ierr)
  !call co_broadcast( arg,ids+1 )
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_bcast_r8(arg,ids)
!
! Broadcast real(8)
!
! - arg : real
! - ids : source destination
!
  use mpi
  implicit none
  real(8), intent(inout) :: arg
  integer, intent(in) :: ids
  integer :: ierr

!--- 2020 Fujitsu
  call MPI_BCAST(arg,1,MPI_REAL8,ids,MPI_COMM_WORLD,ierr)
  !call co_broadcast( arg,ids+1 )
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_bcast_c16(arg,ids)
!
! Broadcast complex(8)
!
! - arg : complex
! - ids : source destination
!
  use mpi
  implicit none
  complex(8), intent(inout) :: arg
  integer, intent(in) :: ids
  integer :: ierr

!--- 2020 Fujitsu
  call MPI_BCAST(arg,1,MPI_COMPLEX16,ids,MPI_COMM_WORLD,ierr)
  !call co_broadcast( arg,ids+1 )
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_bcast_i4_array(arg,ids)
!
! Broadcast integer(4) array
!
  use mpi
  implicit none
  integer, intent(inout) :: arg(:)
  integer, intent(in) :: ids
  integer :: ilen,ierr

!--- 2020 Fujitsu
  ilen=SIZE(arg)
  call MPI_BCAST(arg,ilen,MPI_INTEGER,ids,MPI_COMM_WORLD,ierr)
  !call co_broadcast( arg,ids+1 )
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_bcast_r8_array(arg,ids)
!
! Broadcast real(8) array
!
  use mpi
  implicit none
  real(8), intent(inout) :: arg(:)
  integer, intent(in) :: ids
  integer :: ilen,ierr

!--- 2020 Fujitsu
  ilen=SIZE(arg)
  call MPI_BCAST(arg,ilen,MPI_REAL8,ids,MPI_COMM_WORLD,ierr)
  !call co_broadcast( arg,ids+1 )
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_bcast_c16_array(arg,ids)
!
! Broadcast complex(8) array
!
  use mpi
  implicit none
  complex(8), intent(inout) :: arg(:)
  integer, intent(in) :: ids
  integer :: ilen,ierr

!--- 2020 Fujitsu
  ilen=SIZE(arg)
  call MPI_BCAST(arg,ilen,MPI_COMPLEX16,ids,MPI_COMM_WORLD,ierr)
  !call co_broadcast( arg,ids+1 )
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_init
!
! Initialize this library
!
!coarray use mpi
!coarray  integer :: ierr,iprov

!--- 2020 Fujitsu
use xmp_api
use mpi
integer :: ierr
!--- 2020 Fujitsu end


  ntag=0
!coarray  call MPI_INIT(ierr)

!  call MPI_INIT_THREAD(MPI_THREAD_MULTIPLE,iprov,ierr)
!  call MPI_INIT_THREAD(MPI_THREAD_SINGLE,iprov,ierr)
!  select case(iprov)
!  case (MPI_THREAD_SINGLE)
!    write(*,'("MPI suport MPI_THREAD_SINGLE.")')
!    call MPI_Finalize(ierr)
!    stop
!  case (MPI_THREAD_FUNNELED)
!    write(*,'("MPI suport only MPI_THREAD_FUNNELED.")')
!    call MPI_Finalize(ierr)
!    stop
!  case (MPI_THREAD_SERIALIZED)
!    write(*,'("MPI suport only MPI_THREAD_SERIALIZED.")')
!    call MPI_Finalize(ierr)
!    stop
!  case (MPI_THREAD_MULTIPLE)
!    write(*,'("MPI suport MPI_THREAD_MULTIPLE.")')
!  end select

!coarray
!  call MPI_COMM_RANK(MPI_COMM_WORLD,myid,ierr)
!  call MPI_COMM_SIZE(MPI_COMM_WORLD,numprocs,ierr)
  !--- 2020 Fujitsu
  !myid = this_image() - 1
  !numprocs = num_images()
  call xmp_api_init
  myid = xmp_this_image() - 1
  !numprocs = xmp_num_images()
  call MPI_COMM_SIZE(MPI_COMM_WORLD,numprocs,ierr)
  !--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_finalize
!
! Finalize this library
!
!coarray use mpi
  implicit none
!coarray  integer :: ierr

!coarray  call MPI_Finalize(ierr)
  !--- 2020 Fujitsu
  call xmp_api_finalize
  !--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_node(nodeid,npe)
!
! Get nodeid and total number of nodes
!
!coarray use mpi
  implicit none
  integer, intent(out) :: nodeid,npe

  nodeid=myid
  npe=numprocs

  return
  end subroutine

  subroutine comlib_make_c16(id,node,send,recv,isize)
!
! Make 1to1 (all nodes) communication information
!
! -   id : comlib_data
! - node : nodeid of this process
! - send : 1st component of sender data array (complex(8))
! - recv : 1st component of reciever data array (complex(8))
! - isize : total data size to be send/recieved in unit of bytes
!
  use mpi
  implicit none
  type(comlib_data_c16), intent(out):: id
  integer, intent(in) :: node,isize
  complex(8), target :: send,recv
  type(comlib_data_c16) :: idall(0:numprocs-1)
  integer :: ierr,i
!coarray
  integer :: buf

  idall(myid)%sdesc=node  ! send : myid -> node

!**** make send receive table for all nodes
!--- 2020 Fujitsu
   do i=0,numprocs-1
     call MPI_BCAST(idall(i)%sdesc,1,MPI_INTEGER,i,MPI_COMM_WORLD,ierr)
   !do i=1,numprocs
     !buf = idall(i-1)%sdesc
     !call co_broadcast(buf,i)
     !sync all
     !call xmp_sync_all(ierr)
!--- 2020 Fujitsu end
     idall(i-1)%sdesc = buf
   end do
  do i=0,numprocs-1
    idall(idall(i)%sdesc)%rdesc=i
  enddo
  do i=0,numprocs-1
    ntag=ntag+1
    idall(i)%stag=ntag
  enddo
  do i=0,numprocs-1
    idall(i)%rtag=idall(idall(i)%rdesc)%stag
  enddo

  id%sdesc=idall(myid)%sdesc ! node number (send)
  id%rdesc=idall(myid)%rdesc ! node number (recv)
  id%stag =idall(myid)%stag  ! tag (send)
  id%rtag =idall(myid)%rtag  ! tag (recv)
  id%ssize=isize             ! amount of data in byte (send)
  id%rsize=isize             ! amount of data in byte (recv)
  id%sbuff=>send             ! send buffer (pointer)
  id%rbuff=>recv             ! receive buffer (pointer)

  return
  end subroutine

  subroutine comlib_make_c8(id,node,send,recv,isize)
!
! Make 1to1 (all nodes) communication information
!
! -   id : comlib_data
! - node : nodeid of this process
! - send : 1st component of sender data array (complex(4))
! - recv : 1st component of reciever data array (complex(4))
! - isize : total data size to be send/recieved in unit of bytes
!
  use mpi
  implicit none
  type(comlib_data_c8), intent(out):: id
  integer, intent(in) :: node,isize
  complex(4), target :: send,recv
  type(comlib_data_c8) :: idall(0:numprocs-1)
  integer :: ierr,i
!coarray
  integer :: buf

  idall(myid)%sdesc=node  ! send : myid -> node

!**** make send receive table for all nodes
!--- 2020 Fujitsu
  do i=0,numprocs-1
    call MPI_BCAST(idall(i)%sdesc,1,MPI_INTEGER,i,MPI_COMM_WORLD,ierr)
  !do i=1,numprocs
    !buf = idall(i-1)%sdesc
    !call co_broadcast(buf,i)
    !sync all
    !call xmp_sync_all(ierr)
!--- 2020 Fujitsu end
    idall(i-1)%sdesc = buf
  enddo
  do i=0,numprocs-1
    idall(idall(i)%sdesc)%rdesc=i
  enddo
  do i=0,numprocs-1
    ntag=ntag+1
    idall(i)%stag=ntag
  enddo
  do i=0,numprocs-1
    idall(i)%rtag=idall(idall(i)%rdesc)%stag
  enddo

  id%sdesc=idall(myid)%sdesc ! node number (send)
  id%rdesc=idall(myid)%rdesc ! node number (recv)
  id%stag =idall(myid)%stag  ! tag (send)
  id%rtag =idall(myid)%rtag  ! tag (recv)
  id%ssize=isize             ! amount of data in byte (send)
  id%rsize=isize             ! amount of data in byte (recv)
  id%sbuff=>send             ! send buffer (pointer)
  id%rbuff=>recv             ! receive buffer (pointer)

  return
  end subroutine

  subroutine comlib_isend_c16(id)
!
! Send data indicated by id.
!
!coarray use mpi
  implicit none
  type(comlib_data_c16), intent(inout) :: id
  integer :: ierr

!coarray  call MPI_Isend(id%sbuff,id%ssize,MPI_CHARACTER,id%sdesc,  &
!coarray &               id%stag,MPI_COMM_WORLD,id%sreq,ierr)

  return
  end subroutine

  subroutine comlib_isend_c8(id)
!
! Send data indicated by id.
!
!coarray use mpi
  implicit none
  type(comlib_data_c8), intent(inout) :: id
  integer :: ierr

!coarray  call MPI_Isend(id%sbuff,id%ssize,MPI_CHARACTER,id%sdesc,  &
!coarray &               id%stag,MPI_COMM_WORLD,id%sreq,ierr)

  return
  end subroutine

  subroutine comlib_irecv_c16(id)
!
! Recieve data indicated by id.
!
!coarray use mpi
  implicit none
  type(comlib_data_c16), intent(inout) :: id
  integer :: ierr

!coarray  call MPI_Irecv(id%rbuff,id%rsize,MPI_CHARACTER,id%rdesc,  &
!coarray &               id%rtag,MPI_COMM_WORLD,id%rreq,ierr)

  return
  end subroutine

  subroutine comlib_irecv_c8(id)
!
! Recieve data indicated by id.
!
!coarray use mpi
  implicit none
  type(comlib_data_c8), intent(inout) :: id
  integer :: ierr

!coarray  call MPI_Irecv(id%rbuff,id%rsize,MPI_CHARACTER,id%rdesc,  &
!coarray &               id%rtag,MPI_COMM_WORLD,id%rreq,ierr)

  return
  end subroutine

  subroutine comlib_sendrecv_c16(id)
!
! Send and Recieve data indicated by id.
!
!coarray use mpi
  !--- 2020 Fujitsu
  use xmp_api
  !--- 2020 Fujitsu end
  implicit none
  type(comlib_data_c16), intent(inout) :: id
!coarray
!  integer :: ierr,istat(MPI_STATUS_SIZE)
!
  !--- 2020 Fujitsu
  !complex(8), allocatable :: sbuff(:)[:]
  !complex(8), allocatable :: rbuff(:)[:]
  !
  !allocate(sbuff(id%ssize/16)[*])
  !allocate(rbuff(id%rsize/16)[*])
  !
  complex(8), pointer :: sbuff(:) => null()
  complex(8), pointer :: rbuff(:) => null()
  integer(8) :: s_desc, r_desc
  integer(8), dimension(1) :: s_lb,s_ub, r_lb, r_ub
  integer(4), dimension(1) :: img_dims
  integer(8) :: s_sec, r_sec
  integer(8) :: start1, end1, end2
  integer(4) :: stride1
  integer(4) :: status

  s_lb(1) = 1; s_ub(1) = id%ssize/16
  r_lb(1) = 1; r_ub(1) = id%rsize/16

  call xmp_new_coarray(s_desc, 16, 1, s_lb, s_ub, 1, img_dims)
  call xmp_new_coarray(r_desc, 16, 1, r_lb, r_ub, 1, img_dims)

  call xmp_coarray_bind(s_desc, sbuff)
  call xmp_coarray_bind(r_desc, rbuff)
  !--- 2020 Fujitsu end

!coarray
!  call MPI_SendRecv(id%sbuff,id%ssize,MPI_CHARACTER,id%sdesc,id%stag, &
! &                  id%rbuff,id%rsize,MPI_CHARACTER,id%rdesc,id%rtag, &
! &                  MPI_COMM_WORLD,istat,ierr)
  call copy(sbuff, id%sbuff, id%ssize/16)
  !--- 2020 Fujitsu
  !rbuff(:)[id%sdesc+1] = sbuff(:)
  !sync all
  call xmp_new_array_section(s_sec, 1)
  call xmp_new_array_section(r_sec, 1)
  start1 = 1; stride1 = 1
  end1 = id%ssize/16; end2 = id%rsize/16
  call xmp_array_section_set_triplet(s_sec, 1, start1,end1,stride1, status)
  call xmp_array_section_set_triplet(r_sec, 1, start1,end2,stride1, status)
  img_dims(1) = id%sdesc+1
  call xmp_coarray_put(img_dims, r_desc,r_sec, s_desc,s_sec, status);
  call xmp_sync_all(status)
  !--- 2020 Fujitsu end
  call copy(id%rbuff, rbuff, id%rsize/16)

  !--- 2020 Fujitsu
  !deallocate(rbuff)
  !deallocate(sbuff)
  call xmp_free_array_section(s_sec)
  call xmp_free_array_section(r_sec)
  call xmp_coarray_deallocate(s_desc, status)
  call xmp_coarray_deallocate(r_desc, status)
  !--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_sendrecv_c8(id)
!
! Send and Recieve data indicated by id.
!
!coarray use mpi
  implicit none
  type(comlib_data_c8), intent(inout) :: id
!coarray
!  integer :: ierr,istat(MPI_STATUS_SIZE)
!
!  call MPI_SendRecv(id%sbuff,id%ssize,MPI_CHARACTER,id%sdesc,id%stag, &
! &                  id%rbuff,id%rsize,MPI_CHARACTER,id%rdesc,id%rtag, &
! &                  MPI_COMM_WORLD,istat,ierr)

  return
  end subroutine

  subroutine comlib_check_c16(id)
!
! Check communication ends.
!
!coarray use mpi
  !--- 2020 Fujitsu
  use xmp_api
  !--- 2020 Fujitsu end
  implicit none
  type(comlib_data_c16), intent(inout) :: id
!coarray
!  integer :: sstat(MPI_STATUS_SIZE)
!  integer :: rstat(MPI_STATUS_SIZE),ierr
!
!  call MPI_Wait(id%rreq,rstat,ierr)
!  call MPI_Wait(id%sreq,sstat,ierr)
   !--- 2020 Fujitsu
   !sync all
   integer :: ierr
   call xmp_sync_all(ierr)
   !--- 2020 Fujitsu end
!  write(*,'("RSTAT:",99I12,I8)')rstat,myid
!  write(*,'("SSTAT:",99I12,I8)')sstat,myid

  return
  end subroutine

  subroutine comlib_check_c8(id)
!
! Check communication ends.
!
!coarray use mpi
  !--- 2020 Fujitsu
  use xmp_api
  !--- 2020 Fujitsu end
  implicit none
  type(comlib_data_c8), intent(inout) :: id
!coarray
!  integer :: status(MPI_STATUS_SIZE),ierr
!
!  call MPI_Wait(id%rreq,status,ierr)
!  call MPI_Wait(id%sreq,status,ierr)
  !--- 2020 Fujitsu
  !sync all
  integer :: ierr
  call xmp_sync_all(ierr)
  !--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_barrier
!
! Barrier sync.
!
!coarray use mpi
  !--- 2020 Fujitsu
  use xmp_api
  !--- 2020 Fujitsu end
  implicit none
!coarray
!  integer :: ierr
!
!  call MPI_Barrier(MPI_COMM_WORLD,ierr)
  !--- 2020 Fujitsu
  !sync all
  integer :: ierr
  call xmp_sync_all(ierr)
  !--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_sumcast_i4_array(i4)
!
! sum and broadcast of integer(4) data array
!
!coarray use mpi
  implicit none
  integer, intent(inout) :: i4(:)
  integer :: i4tmp(SIZE(i4))
  integer :: ierr,isize

  isize=SIZE(i4)
!coarray  call MPI_Allreduce(i4,i4tmp,isize,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,ierr)
  i4=i4tmp

  return
  end subroutine

  subroutine comlib_sumcast_r8_array(r8)
!
! sum and broadcast of real(8) data array
!
!coarray use mpi
  implicit none
  real(8), intent(inout) :: r8(:)
  real(8) :: r8tmp(SIZE(r8))
  integer :: ierr,isize

  isize=SIZE(r8)
!coarray  call MPI_Allreduce(r8,r8tmp,isize,MPI_REAL8,MPI_SUM,MPI_COMM_WORLD,ierr)
  r8=r8tmp

  return
  end subroutine

  subroutine comlib_sumcast_r4_array(r4)
!
! sum and broadcast of real(4) data array
!
!coarray use mpi
  implicit none
  real(4), intent(inout) :: r4(:)
  real(4) :: r4tmp(SIZE(r4))
  integer :: ierr,isize

  isize=SIZE(r4)
!coarray  call MPI_Allreduce(r4,r4tmp,isize,MPI_REAL4,MPI_SUM,MPI_COMM_WORLD,ierr)
  r4=r4tmp

  return
  end subroutine

  subroutine comlib_sumcast_c16_array(c16)
!
! sum and broadcast of complex(8) data array
!
!coarray use mpi
  implicit none
  complex(8), intent(inout) :: c16(:)
  complex(8) :: c16tmp(SIZE(c16))
  integer :: ierr,isize

  isize=SIZE(c16)
!coarray  call MPI_Allreduce(c16,c16tmp,isize,MPI_COMPLEX16,MPI_SUM,MPI_COMM_WORLD,ierr)
  c16=c16tmp

  return
  end subroutine

  subroutine comlib_sumcast_c8_array(c8)
!
! sum and broadcast of complex(4) data array
!
!coarray use mpi
  implicit none
  complex(4), intent(inout) :: c8(:)
  complex(4) :: c8tmp(SIZE(c8))
  integer :: ierr,isize

  isize=SIZE(c8)
!coarray  call MPI_Allreduce(c8,c8tmp,isize,MPI_COMPLEX8,MPI_SUM,MPI_COMM_WORLD,ierr)
  c8=c8tmp

  return
  end subroutine

  subroutine comlib_sumcast_i4(i4)
!
! sum and broadcast of integer(4) data
!
  use mpi
  implicit none
  integer, intent(inout) :: i4
  integer :: i4tmp
!coarray
  integer :: ierr
!
!--- 2020 Fujitsu
  call MPI_Allreduce(i4,i4tmp,1,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,ierr)
  !i4tmp = i4
  !call co_sum(i4tmp)
  i4 = i4tmp
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_sumcast_r8(r8)
!
! sum and broadcast of real(8) data
!
  use mpi
  implicit none
  real(8), intent(inout) :: r8
  real(8) :: r8tmp
!coarray
  integer :: ierr
!
!--- 2020 Fujitsu
  call MPI_Allreduce(r8,r8tmp,1,MPI_REAL8,MPI_SUM,MPI_COMM_WORLD,ierr)
  !r8tmp = r8
  !call co_sum(r8tmp)
  r8 = r8tmp
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_sumcast_r4(r4)
!
! sum and broadcast of real(4) data
!
  use mpi
  implicit none
  real(4), intent(inout) :: r4
  real(4) :: r4tmp
!coarray
  integer :: ierr
!
!--- 2020 Fujitsu
  call MPI_Allreduce(r4,r4tmp,1,MPI_REAL4,MPI_SUM,MPI_COMM_WORLD,ierr)
  !r4tmp = r4
  !call co_sum(r4tmp)
  r4 = r4tmp
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_sumcast_c16(c16)
!
! sum and broadcast of complex(8) data
!
   use mpi
  implicit none
  complex(8), intent(inout) :: c16
  complex(8) :: c16tmp
!coarray
  integer :: ierr
!
!--- 2020 Fujitsu
  call MPI_Allreduce(c16,c16tmp,1,MPI_COMPLEX16,MPI_SUM,MPI_COMM_WORLD,ierr)
  c16tmp = c16
  !call co_sum(c16tmp)
  !c16 = c16tmp
!--- 2020 Fujitsu end

  return
  end subroutine

  subroutine comlib_sumcast_c8(c8)
!
! sum and broadcast of complex(4) data
!
  use mpi
  implicit none
  complex(4), intent(inout) :: c8
  complex(4) :: c8tmp
!coarray
  integer :: ierr
!
!--- 2020 Fujitsu
  call MPI_Allreduce(c8,c8tmp,1,MPI_COMPLEX8,MPI_SUM,MPI_COMM_WORLD,ierr)
  !c8tmp = c8
  !call co_sum(c8tmp)
  c8 = c8tmp
!--- 2020 Fujitsu end

  return
  end subroutine

end module
