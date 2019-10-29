open Util
open BankAccounts

module Sim = struct
  module Agents = HMap(Int)

                          
  type bank = { id : ident ;
                nom : string ;
                capitalAccId : ident }

  type menage = { id : ident ;
                  nom : string ;
                  biens : int }

  type machine = { etape : int }

  type firm = { id : int ;
                nom : string ;
                prix : amount ;
                machines : machine list ;
                biens : int }

  type t = { periodNb : int ;
             bank : bank ;
             menages : menage Agents.t ;
             firms : firm Agents.t }

  let init : t = { periodNb = 0 ;
                   bank = {
                     id = 0 ;
                     nom = "bank" ;
                     capitalAccId = Accs.bankIdent } ;
                   menages = Agents.nil ;
                   firms = Agents.nil }
end
          
module SimParam = struct
  type t = { nb_menages : int ;
             nb_firms : int ;
             prix : amount ;
             salaire : amount ;
             etapeMax : int ;
             nbMachinesParFirm : int ;
             nbBiensParMachine : int ;
             menageVision : int }
end
                    
module SimEnv = struct
  type t = { nextIdent : ident ;
             rand : Rand.t }
    let init = { nextIdent = 0 ;
                 rand = Rand.init (Array.make 0 0) }
end
                  
module SimLog = struct
  type data =
    | CreationMenage of ident
    | CreationFirm of ident
    | RevenuUniversel of ident * amount
    | DebutPeriod of int  (* num period *)
    | TravailMachines of ident * int * int  (* nb etapes, nb biens finis *)
    | Achat of ident * ident * int * amount  (* menage firm nb_achats prix *)
                                 
  type t = data Fifo.t
  let nil = Fifo.nil
  let add loga logb = Fifo.concat loga logb

end

open Sim
open SimLog

let menage2s (menage : menage) accs : string =
  i2s menage.id ^ " "
  ^ "[amount " ^ i2s (Accs.get_amount menage.id accs) ^ "] "
  ^ "[biens " ^ i2s menage.biens ^ "]"

let menages2s menages accs : string =
  Liste.fold_left (Liste.take_atmax 100 (Agents.values menages)) ""
     (fun men s -> s ^ "\n" ^ menage2s men accs)

let machines2s machines : string =
  Liste.fold_left machines ""
    (fun machine s -> s ^ " " ^ i2s machine.etape)
    
let firm2s (firm : firm) accs : string =
  i2s firm.id ^ " "
  ^ "[amount " ^ i2s (Accs.get_amount firm.id accs) ^ "] "
  ^ "[biens " ^ i2s firm.biens ^ "] "
  ^ "[machines" ^ machines2s firm.machines ^ "]"

let firms2s firms accs : string =
  Liste.fold_left (Agents.values firms) ""
    (fun firm s -> s ^ "\n" ^ firm2s firm accs)
    
    
let log2s log : string =
  match log with
  | CreationMenage id -> "CreationMenage %d" ^ i2s id
  | CreationFirm id -> "CreationFirm " ^ i2s id
  | RevenuUniversel(id, am) -> "RevenuUniversel " ^ i2s id ^ " " ^ i2s am
  | DebutPeriod n -> "DebutPeriod " ^ i2s n
  | TravailMachines (id, ets, fins) ->
     "TravailMachines " ^ i2s id ^ " " ^ i2s ets ^ " " ^ i2s fins
  | Achat (idm, idf, nb, am) ->
     "Achat " ^ i2s idm ^ " " ^ i2s idf ^ " " ^ i2s nb ^ " " ^ i2s am
       
let logs2s logs : string =
  Liste.fold_left (Fifo.takeLast 50 logs) ""
    (fun log s -> s ^ "\n" ^ log2s log)
    
    
let sim2s sim env logs accs : string =
  "=== Period " ^ i2s sim.periodNb
  ^ " =====================================================\n"
  ^ "Bank [lend " ^ i2s (Accs.get_amount sim.bank.capitalAccId accs) ^ "]\n"
  ^ "--- Ménages (first 100) ------------------------------------------"
  ^ menages2s sim.menages accs ^ "\n"
  ^ "--- Firms --------------------------------------------------------"
  ^ firms2s sim.firms accs ^ "\n"
  ^ "--- Logs (last 50) -----------------------------------------------"
  ^ logs2s logs 

let display_repl sim (param:SimParam.t) accs logs env :unit =
  let spc () = print_char ' ' in
  let line = print_newline in
  let pi = print_int in
  let pf = print_float in
  let bal id = Accs.get_amount id accs in
  let cash_bank = bal Accs.bankIdent in
  let nb_firms = param.nb_firms in
  let (cash_firms, nb_biens_firms, sum_prix_firms) =
    Agents.fold sim.firms (0,0,0)
       (fun id firm (cash_firms, nb_biens_firms, sum_prix_firms) ->
          let cash_firms = cash_firms + (bal id) in
          let nb_biens_firms = nb_biens_firms + firm.biens in
          let sum_prix_firms = sum_prix_firms + firm.prix in
          (cash_firms, nb_biens_firms, sum_prix_firms))
  in
  let prix_moyen_firms =
    if nb_firms = 0 then 0.0 else (i2f sum_prix_firms) /. (i2f nb_firms)
  in
  let (cash_menages, nb_biens_menages) =
    Agents.fold sim.menages (0,0) 
       (fun id menage (cash_menages, nb_biens_menages) ->
          let cash_menages = cash_menages + (bal id) in
          let nb_biens_menages = nb_biens_menages + menage.biens in
          (cash_menages, nb_biens_menages))
  in
  let (nb_achats, nb_biens_produits) =
    Fifo.fold (0, 0) (fun (nb_achats, nb_biens_produits) log ->
          match log with
          | Achat (_, _, achats, _) -> (nb_achats + achats, nb_biens_produits)
          | TravailMachines (_, _, biens_produits) ->
             (nb_achats, nb_biens_produits + biens_produits)
          | other -> (nb_achats, nb_biens_produits)
       ) logs
  in
  pi cash_bank ; spc () ; pi cash_firms ; spc () ; pi cash_menages ; line () ;
  pi nb_biens_firms ; spc () ; pi nb_biens_menages ; spc () ;
  pi nb_biens_produits ; line () ;
  pf prix_moyen_firms ; line () ;
  pi nb_achats ; line () ;
  print_endline "fin"
