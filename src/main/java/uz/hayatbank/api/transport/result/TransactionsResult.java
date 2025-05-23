package uz.hayatbank.api.transport.result;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.bean.UserTransactionBean;
import uz.hayatbank.api.transport.GenericPagingResult;

import java.util.List;

@EqualsAndHashCode(callSuper = true)
@Data
public class TransactionsResult extends GenericPagingResult {
    private List<UserTransactionBean> transactions;
}
