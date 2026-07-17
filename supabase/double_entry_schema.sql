-- ----------------------------------------------------
-- DATABASE SCHEMA: DOUBLE-ENTRY BOOKKEEPING (JURNAL UMUM)
-- YAYASAN FINANCE (ISAK 35 COMPLIANT)
-- ----------------------------------------------------

-- 1. Create journal_entries table (Voucher Header)
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  foundation_id uuid REFERENCES public.foundations(id) ON DELETE CASCADE NOT NULL,
  proof_number text NOT NULL,
  transaction_date date NOT NULL DEFAULT current_date,
  description text,
  change_reason text,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  -- Nomor bukti harus unik per yayasan
  CONSTRAINT journal_entries_foundation_proof_unique UNIQUE (foundation_id, proof_number)
);

-- 2. Create journal_items table (Voucher Lines)
CREATE TABLE IF NOT EXISTS public.journal_items (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  entry_id uuid REFERENCES public.journal_entries(id) ON DELETE CASCADE NOT NULL,
  account_id uuid REFERENCES public.chart_of_accounts(id) ON DELETE RESTRICT NOT NULL,
  debit numeric(15, 2) NOT NULL DEFAULT 0.00 CHECK (debit >= 0),
  credit numeric(15, 2) NOT NULL DEFAULT 0.00 CHECK (credit >= 0),
  project_id uuid REFERENCES public.projects(id) ON DELETE SET NULL,
  memo text,
  -- Pastikan setiap baris adalah debit atau kredit, tidak boleh nol keduanya atau diisi keduanya
  CONSTRAINT journal_items_debit_credit_check CHECK (
    (debit > 0 AND credit = 0) OR (debit = 0 AND credit > 0)
  )
);

-- 3. Enable RLS
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_items ENABLE ROW LEVEL SECURITY;

-- 4. RLS policies for journal_entries
DROP POLICY IF EXISTS "Members can view journal_entries" ON public.journal_entries;
CREATE POLICY "Members can view journal_entries"
  ON public.journal_entries FOR SELECT
  TO authenticated
  USING (public.is_member_of(foundation_id));

DROP POLICY IF EXISTS "Admin and Bendahara can insert journal_entries" ON public.journal_entries;
CREATE POLICY "Admin and Bendahara can insert journal_entries"
  ON public.journal_entries FOR INSERT
  TO authenticated
  WITH CHECK (public.is_authorized_to_transact(foundation_id));

DROP POLICY IF EXISTS "Admin and Bendahara can update journal_entries" ON public.journal_entries;
CREATE POLICY "Admin and Bendahara can update journal_entries"
  ON public.journal_entries FOR UPDATE
  TO authenticated
  USING (public.is_authorized_to_transact(foundation_id));

DROP POLICY IF EXISTS "Admin can delete journal_entries" ON public.journal_entries;
CREATE POLICY "Admin can delete journal_entries"
  ON public.journal_entries FOR DELETE
  TO authenticated
  USING (public.is_admin_of(foundation_id));

-- 5. RLS policies for journal_items
DROP POLICY IF EXISTS "Members can view journal_items" ON public.journal_items;
CREATE POLICY "Members can view journal_items"
  ON public.journal_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.journal_entries
      WHERE id = journal_items.entry_id AND public.is_member_of(foundation_id)
    )
  );

DROP POLICY IF EXISTS "Admin and Bendahara can insert journal_items" ON public.journal_items;
CREATE POLICY "Admin and Bendahara can insert journal_items"
  ON public.journal_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.journal_entries
      WHERE id = journal_items.entry_id AND public.is_authorized_to_transact(foundation_id)
    )
  );

DROP POLICY IF EXISTS "Admin and Bendahara can update journal_items" ON public.journal_items;
CREATE POLICY "Admin and Bendahara can update journal_items"
  ON public.journal_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.journal_entries
      WHERE id = journal_items.entry_id AND public.is_authorized_to_transact(foundation_id)
    )
  );

DROP POLICY IF EXISTS "Admin and Bendahara can delete journal_items" ON public.journal_items;
CREATE POLICY "Admin and Bendahara can delete journal_items"
  ON public.journal_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.journal_entries
      WHERE id = journal_items.entry_id AND public.is_authorized_to_transact(foundation_id)
    )
  );

-- 6. Trigger for requiring change_reason on update of journal_entries
CREATE OR REPLACE FUNCTION public.check_journal_change_reason()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.change_reason IS NULL OR length(trim(NEW.change_reason)) < 5 THEN
      RAISE EXCEPTION 'Pengubahan jurnal wajib menyertakan alasan (change_reason) minimal 5 karakter.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_journal_change_reason_trigger ON public.journal_entries;
CREATE TRIGGER check_journal_change_reason_trigger
  BEFORE UPDATE ON public.journal_entries
  FOR EACH ROW EXECUTE PROCEDURE public.check_journal_change_reason();

-- 7. Stored Procedure: Create Journal Entry atomically with balance verification
CREATE OR REPLACE FUNCTION public.create_journal_entry(
  p_foundation_id uuid,
  p_proof_number text,
  p_transaction_date date,
  p_description text,
  p_items jsonb -- Array of objects: account_id, debit, credit, project_id, memo
)
RETURNS uuid AS $$
DECLARE
  v_entry_id uuid;
  v_item jsonb;
  v_total_debit numeric(15, 2) := 0;
  v_total_credit numeric(15, 2) := 0;
  v_debit numeric(15, 2);
  v_credit numeric(15, 2);
BEGIN
  -- Validate if user is authorized
  IF NOT public.is_authorized_to_transact(p_foundation_id) THEN
    RAISE EXCEPTION 'Aksi tidak diizinkan untuk pengguna saat ini.';
  END IF;

  -- Validate balance first from jsonb array
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_debit := coalesce((v_item->>'debit')::numeric, 0.00);
    v_credit := coalesce((v_item->>'credit')::numeric, 0.00);
    
    IF v_debit < 0 OR v_credit < 0 THEN
      RAISE EXCEPTION 'Nominal debit dan kredit tidak boleh negatif.';
    END IF;
    
    IF (v_debit > 0 AND v_credit > 0) OR (v_debit = 0 AND v_credit = 0) THEN
      RAISE EXCEPTION 'Setiap baris jurnal harus berupa debit atau kredit (tidak boleh keduanya atau nol keduanya).';
    END IF;
    
    v_total_debit := v_total_debit + v_debit;
    v_total_credit := v_total_credit + v_credit;
  END LOOP;

  IF v_total_debit != v_total_credit THEN
    RAISE EXCEPTION 'Total Debit (%) harus sama dengan Total Kredit (%). Jurnal tidak seimbang.', v_total_debit, v_total_credit;
  END IF;

  -- Insert header
  INSERT INTO public.journal_entries (
    foundation_id,
    proof_number,
    transaction_date,
    description,
    created_by
  ) VALUES (
    p_foundation_id,
    p_proof_number,
    p_transaction_date,
    p_description,
    auth.uid()
  ) RETURNING id INTO v_entry_id;

  -- Insert items
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    INSERT INTO public.journal_items (
      entry_id,
      account_id,
      debit,
      credit,
      project_id,
      memo
    ) VALUES (
      v_entry_id,
      (v_item->>'account_id')::uuid,
      coalesce((v_item->>'debit')::numeric, 0.00),
      coalesce((v_item->>'credit')::numeric, 0.00),
      (v_item->>'project_id')::uuid,
      v_item->>'memo'
    );
  END LOOP;

  RETURN v_entry_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Stored Procedure: Update Journal Entry atomically with balance verification
CREATE OR REPLACE FUNCTION public.update_journal_entry(
  p_entry_id uuid,
  p_proof_number text,
  p_transaction_date date,
  p_description text,
  p_change_reason text,
  p_items jsonb
)
RETURNS void AS $$
DECLARE
  v_foundation_id uuid;
  v_item jsonb;
  v_total_debit numeric(15, 2) := 0;
  v_total_credit numeric(15, 2) := 0;
  v_debit numeric(15, 2);
  v_credit numeric(15, 2);
BEGIN
  -- Get foundation_id and check authorization
  SELECT foundation_id INTO v_foundation_id FROM public.journal_entries WHERE id = p_entry_id;
  IF v_foundation_id IS NULL THEN
    RAISE EXCEPTION 'Entri jurnal tidak ditemukan.';
  END IF;
  
  IF NOT public.is_authorized_to_transact(v_foundation_id) THEN
    RAISE EXCEPTION 'Aksi tidak diizinkan untuk pengguna saat ini.';
  END IF;

  -- Validate change reason length
  IF p_change_reason IS NULL OR length(trim(p_change_reason)) < 5 THEN
    RAISE EXCEPTION 'Pengubahan jurnal wajib menyertakan alasan (change_reason) minimal 5 karakter.';
  END IF;

  -- Validate balance first from jsonb array
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_debit := coalesce((v_item->>'debit')::numeric, 0.00);
    v_credit := coalesce((v_item->>'credit')::numeric, 0.00);
    
    IF v_debit < 0 OR v_credit < 0 THEN
      RAISE EXCEPTION 'Nominal debit dan kredit tidak boleh negatif.';
    END IF;
    
    IF (v_debit > 0 AND v_credit > 0) OR (v_debit = 0 AND v_credit = 0) THEN
      RAISE EXCEPTION 'Setiap baris jurnal harus berupa debit atau kredit (tidak boleh keduanya atau nol keduanya).';
    END IF;
    
    v_total_debit := v_total_debit + v_debit;
    v_total_credit := v_total_credit + v_credit;
  END LOOP;

  IF v_total_debit != v_total_credit THEN
    RAISE EXCEPTION 'Total Debit (%) harus sama dengan Total Kredit (%). Jurnal tidak seimbang.', v_total_debit, v_total_credit;
  END IF;

  -- Update header
  UPDATE public.journal_entries SET
    proof_number = p_proof_number,
    transaction_date = p_transaction_date,
    description = p_description,
    change_reason = p_change_reason
  WHERE id = p_entry_id;

  -- Re-insert items (Delete existing and insert new ones)
  DELETE FROM public.journal_items WHERE entry_id = p_entry_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    INSERT INTO public.journal_items (
      entry_id,
      account_id,
      debit,
      credit,
      project_id,
      memo
    ) VALUES (
      p_entry_id,
      (v_item->>'account_id')::uuid,
      coalesce((v_item->>'debit')::numeric, 0.00),
      coalesce((v_item->>'credit')::numeric, 0.00),
      (v_item->>'project_id')::uuid,
      v_item->>'memo'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Automatic Transaction-to-Journal Trigger
CREATE OR REPLACE FUNCTION public.post_transaction_to_journal()
RETURNS TRIGGER AS $$
DECLARE
  v_cash_account_id uuid;
  v_contra_account_id uuid;
  v_entry_id uuid;
  v_proof_number text;
BEGIN
  -- Only post if status is 'approved'
  IF NEW.status = 'approved' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'approved') THEN
     
    -- 1. Find Kas Utama (code '1110')
    SELECT id INTO v_cash_account_id 
    FROM public.chart_of_accounts 
    WHERE foundation_id = NEW.foundation_id AND code = '1110'
    LIMIT 1;

    IF v_cash_account_id IS NULL THEN
      SELECT id INTO v_cash_account_id 
      FROM public.chart_of_accounts 
      WHERE foundation_id = NEW.foundation_id AND code LIKE '11%'
      LIMIT 1;
    END IF;

    -- 2. Use selected account_id or match by category name
    v_contra_account_id := NEW.account_id;

    IF v_contra_account_id IS NULL THEN
      SELECT id INTO v_contra_account_id 
      FROM public.chart_of_accounts 
      WHERE foundation_id = NEW.foundation_id AND name ILIKE NEW.category
      LIMIT 1;
    END IF;

    -- Fallback
    IF v_contra_account_id IS NULL THEN
      IF NEW.type = 'income' THEN
        SELECT id INTO v_contra_account_id 
        FROM public.chart_of_accounts 
        WHERE foundation_id = NEW.foundation_id AND code = '4110'
        LIMIT 1;
      ELSE
        SELECT id INTO v_contra_account_id 
        FROM public.chart_of_accounts 
        WHERE foundation_id = NEW.foundation_id AND code = '5240'
        LIMIT 1;
      END IF;
    END IF;

    IF v_cash_account_id IS NULL OR v_contra_account_id IS NULL THEN
      RETURN NEW;
    END IF;

    -- TX prefix proof number
    v_proof_number := 'TX-' || substring(NEW.id::text from 1 for 8);

    IF EXISTS (
      SELECT 1 FROM public.journal_entries 
      WHERE foundation_id = NEW.foundation_id AND proof_number = v_proof_number
    ) THEN
      RETURN NEW;
    END IF;

    -- Insert Header
    INSERT INTO public.journal_entries (
      foundation_id,
      proof_number,
      transaction_date,
      description,
      created_by
    ) VALUES (
      NEW.foundation_id,
      v_proof_number,
      NEW.transaction_date,
      coalesce(NEW.description, 'Posting otomatis dari transaksi: ' || NEW.category),
      NEW.created_by
    ) RETURNING id INTO v_entry_id;

    -- Insert Items
    IF NEW.type = 'income' THEN
      INSERT INTO public.journal_items (entry_id, account_id, debit, credit, project_id, memo)
      VALUES 
        (v_entry_id, v_cash_account_id, NEW.amount, 0.00, NEW.project_id, NEW.description),
        (v_entry_id, v_contra_account_id, 0.00, NEW.amount, NEW.project_id, NEW.description);
    ELSE
      INSERT INTO public.journal_items (entry_id, account_id, debit, credit, project_id, memo)
      VALUES 
        (v_entry_id, v_contra_account_id, NEW.amount, 0.00, NEW.project_id, NEW.description),
        (v_entry_id, v_cash_account_id, 0.00, NEW.amount, NEW.project_id, NEW.description);
    END IF;

  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_transaction_approved_post_journal_trigger ON public.transactions;
CREATE TRIGGER on_transaction_approved_post_journal_trigger
  AFTER INSERT OR UPDATE ON public.transactions
  FOR EACH ROW EXECUTE PROCEDURE public.post_transaction_to_journal();

-- 10. Historical Data One-Time Migration Block
DO $$
DECLARE
  v_tx RECORD;
  v_cash_account_id uuid;
  v_contra_account_id uuid;
  v_entry_id uuid;
  v_proof_number text;
BEGIN
  FOR v_tx IN 
    SELECT * FROM public.transactions WHERE status = 'approved'
  LOOP
    v_proof_number := 'TX-' || substring(v_tx.id::text from 1 for 8);

    IF NOT EXISTS (
      SELECT 1 FROM public.journal_entries 
      WHERE foundation_id = v_tx.foundation_id AND proof_number = v_proof_number
    ) THEN
      SELECT id INTO v_cash_account_id 
      FROM public.chart_of_accounts 
      WHERE foundation_id = v_tx.foundation_id AND code = '1110'
      LIMIT 1;

      IF v_cash_account_id IS NULL THEN
        SELECT id INTO v_cash_account_id 
        FROM public.chart_of_accounts 
        WHERE foundation_id = v_tx.foundation_id AND code LIKE '11%'
        LIMIT 1;
      END IF;

      v_contra_account_id := v_tx.account_id;

      IF v_contra_account_id IS NULL THEN
        SELECT id INTO v_contra_account_id 
        FROM public.chart_of_accounts 
        WHERE foundation_id = v_tx.foundation_id AND name ILIKE v_tx.category
        LIMIT 1;
      END IF;

      IF v_contra_account_id IS NULL THEN
        IF v_tx.type = 'income' THEN
          SELECT id INTO v_contra_account_id 
          FROM public.chart_of_accounts 
          WHERE foundation_id = v_tx.foundation_id AND code = '4110'
          LIMIT 1;
        ELSE
          SELECT id INTO v_contra_account_id 
          FROM public.chart_of_accounts 
          WHERE foundation_id = v_tx.foundation_id AND code = '5240'
          LIMIT 1;
        END IF;
      END IF;

      IF v_cash_account_id IS NOT NULL AND v_contra_account_id IS NOT NULL THEN
        INSERT INTO public.journal_entries (
          foundation_id,
          proof_number,
          transaction_date,
          description,
          created_by,
          created_at
        ) VALUES (
          v_tx.foundation_id,
          v_proof_number,
          v_tx.transaction_date,
          coalesce(v_tx.description, 'Posting otomatis dari transaksi: ' || v_tx.category),
          v_tx.created_by,
          v_tx.created_at
        ) RETURNING id INTO v_entry_id;

        IF v_tx.type = 'income' THEN
          INSERT INTO public.journal_items (entry_id, account_id, debit, credit, project_id, memo)
          VALUES 
            (v_entry_id, v_cash_account_id, v_tx.amount, 0.00, v_tx.project_id, v_tx.description),
            (v_entry_id, v_contra_account_id, 0.00, v_tx.amount, v_tx.project_id, v_tx.description);
        ELSE
          INSERT INTO public.journal_items (entry_id, account_id, debit, credit, project_id, memo)
          VALUES 
            (v_entry_id, v_contra_account_id, v_tx.amount, 0.00, v_tx.project_id, v_tx.description),
            (v_entry_id, v_cash_account_id, 0.00, v_tx.amount, v_tx.project_id, v_tx.description);
        END IF;
      END IF;
    END IF;
  END LOOP;
END;
$$;
