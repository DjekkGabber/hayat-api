package uz.hayatbank.api.transport.argument;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.transport.GenericPagingArgument;

@EqualsAndHashCode(callSuper = true)
@Data
public class TransactionsArgument extends GenericPagingArgument {
    private String user_phone;
    private Integer transaction_type;
    private String date_from;
    private String date_to;
}
