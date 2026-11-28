-- पहले से चल रहे डेटाबेस के लिए (नई स्कीमा में यह कॉलम पहले से है)
ALTER TABLE donations ADD COLUMN IF NOT EXISTS receipt_token TEXT;
